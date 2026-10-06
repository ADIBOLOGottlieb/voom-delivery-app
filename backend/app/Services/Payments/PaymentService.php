<?php

namespace App\Services\Payments;

use App\Enums\DeliveryStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Models\Delivery;
use App\Models\Payment;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/** Orchestration des paiements via agrégateur : lancement, vérification, confirmation. */
class PaymentService
{
    /** Au-delà, une tentative sans réponse de l'agrégateur est abandonnée. */
    private const PENDING_TIMEOUT_MINUTES = 30;

    /** Une tentative plus récente bloque la création d'une nouvelle (double débit). */
    private const RECENT_PENDING_MINUTES = 3;

    /** Mode choisi dans Admin › Réglages : auto, manual ou simulation. */
    public function mode(): string
    {
        return Setting::get('payment_mode') ?: 'auto';
    }

    public function gateway(): ?PaymentGateway
    {
        return match ($this->mode()) {
            'simulation' => app(SimulationGateway::class),
            'manual' => null,
            default => $this->configuredGateway(),
        };
    }

    /** Agrégateur réel défini dans .env (PAYMENT_GATEWAY), s'il a ses clés. */
    public function configuredGateway(): ?PaymentGateway
    {
        $gateway = match (config('payments.gateway')) {
            'kkiapay' => app(KkiapayGateway::class),
            'paygate' => app(PaygateGateway::class),
            default => null,
        };

        return $gateway?->isConfigured() ? $gateway : null;
    }

    /** Résultat choisi sur la page de simulation (refusé hors mode simulation). */
    public function simulate(Payment $payment, bool $success): void
    {
        if ($payment->gateway !== 'simulation' || $payment->status !== PaymentStatus::Pending || $this->mode() !== 'simulation') {
            return;
        }

        $success
            ? $this->markPaid($payment)
            : $payment->forceFill(['status' => PaymentStatus::Failed])->save();
    }

    /**
     * Validation par l'admin sans passer par l'app (espèces, virement vérifié à la main, test).
     * Crée une trace de paiement confirmée et débloque l'assignation du livreur.
     */
    public function confirmByAdmin(Delivery $delivery, User $admin, PaymentMethod $method, ?string $reference): Payment
    {
        if ($delivery->status === DeliveryStatus::Cancelled || $delivery->payment_status === PaymentStatus::Verified) {
            throw ValidationException::withMessages(['payment' => 'Livraison annulée ou déjà payée.']);
        }

        return DB::transaction(function () use ($delivery, $admin, $method, $reference) {
            // Les preuves encore en attente sont closes : c'est l'admin qui tranche.
            $delivery->payments()->whereIn('status', [PaymentStatus::Pending, PaymentStatus::Submitted])
                ->update(['status' => PaymentStatus::Rejected, 'rejection_reason' => 'Remplacé par une validation manuelle']);

            $payment = $delivery->payments()->create([
                'method' => $method,
                'transaction_ref' => $reference,
                'payer_phone' => $delivery->client->phone_number,
                'amount' => $delivery->total_amount,
                'status' => PaymentStatus::Verified,
                'reviewed_by' => $admin->id,
                'reviewed_at' => now(),
            ]);
            $delivery->forceFill(['payment_status' => PaymentStatus::Verified])->save();

            return $payment;
        });
    }

    /** Paiement automatique actif ? Sinon l'app utilise le mode manuel (capture d'écran). */
    public function enabled(): bool
    {
        return $this->gateway() !== null;
    }

    /**
     * @return array{payment: Payment, mode: string, message: string, redirect_url?: string}
     */
    public function checkout(Delivery $delivery, PaymentMethod $method, string $phone): array
    {
        $gateway = $this->gateway() ?? throw ValidationException::withMessages([
            'payment' => "Le paiement en ligne n'est pas activé. Utilisez le paiement par capture d'écran.",
        ]);

        // Tentatives précédentes : un paiement validé entre-temps ne doit pas être redemandé.
        foreach ($delivery->payments()->where('status', PaymentStatus::Pending)->get() as $pending) {
            $this->refresh($pending);
            if ($pending->status === PaymentStatus::Pending && $pending->created_at->gt(now()->subMinutes(self::RECENT_PENDING_MINUTES))) {
                throw ValidationException::withMessages([
                    'payment' => 'Un paiement est déjà en cours : validez-le sur votre téléphone ou réessayez dans quelques minutes.',
                ]);
            }
            if ($pending->status === PaymentStatus::Pending) {
                $pending->forceFill(['status' => PaymentStatus::Failed])->save();
            }
        }

        if (! $delivery->refresh()->canSubmitPayment()) {
            throw ValidationException::withMessages(['payment' => 'Cette livraison est déjà payée ou ne peut plus être payée.']);
        }

        $payment = $delivery->payments()->create([
            'method' => $method,
            'gateway' => $gateway->name(),
            'checkout_token' => (string) Str::uuid(),
            'payer_phone' => $phone,
            'amount' => $delivery->total_amount,
            'status' => PaymentStatus::Pending,
        ]);

        try {
            $result = $gateway->start($payment);
        } catch (ValidationException $e) {
            $payment->forceFill(['status' => PaymentStatus::Failed])->save();
            throw $e;
        }

        return ['payment' => $payment, ...$result];
    }

    /** Vérifie une tentative en attente auprès de l'agrégateur et applique le résultat. */
    public function refresh(Payment $payment): Payment
    {
        if ($payment->status !== PaymentStatus::Pending || ! $payment->isGateway()) {
            return $payment;
        }

        $gateway = match ($payment->gateway) {
            'kkiapay' => app(KkiapayGateway::class),
            'paygate' => app(PaygateGateway::class),
            'simulation' => app(SimulationGateway::class),
            default => null,
        };

        $paid = $gateway?->check($payment);

        if ($paid === true) {
            $this->markPaid($payment);
        } elseif ($paid === false || $payment->created_at->lt(now()->subMinutes(self::PENDING_TIMEOUT_MINUTES))) {
            $payment->forceFill(['status' => PaymentStatus::Failed])->save();
        }

        return $payment->refresh();
    }

    /** KKiaPay : rattache l'identifiant de transaction renvoyé par le widget ou le webhook. */
    public function attachReference(Payment $payment, string $transactionId): void
    {
        if ($payment->gateway_reference || $payment->status !== PaymentStatus::Pending) {
            return;
        }

        // Une même transaction ne peut pas payer deux livraisons.
        $usedElsewhere = Payment::where('gateway', $payment->gateway)
            ->where('gateway_reference', $transactionId)
            ->whereKeyNot($payment->id)
            ->exists();

        if (! $usedElsewhere) {
            $payment->forceFill(['gateway_reference' => $transactionId])->save();
        }
    }

    private function markPaid(Payment $payment): void
    {
        DB::transaction(function () use ($payment) {
            $payment->forceFill(['status' => PaymentStatus::Verified, 'reviewed_at' => now()])->save();
            $payment->delivery->forceFill(['payment_status' => PaymentStatus::Verified])->save();
        });
    }
}
