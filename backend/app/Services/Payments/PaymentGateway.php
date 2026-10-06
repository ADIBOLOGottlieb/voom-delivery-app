<?php

namespace App\Services\Payments;

use App\Models\Payment;

/** Agrégateur de paiement mobile money (Flooz / Mixx by Yas). */
interface PaymentGateway
{
    /** Nom technique stocké dans payments.gateway (kkiapay, paygate). */
    public function name(): string;

    /** Les clés nécessaires sont-elles configurées ? */
    public function isConfigured(): bool;

    /**
     * Lance le paiement auprès de l'agrégateur.
     *
     * @return array{mode: 'ussd'|'redirect', message: string, redirect_url?: string}
     *
     * @throws \Illuminate\Validation\ValidationException si l'agrégateur refuse la demande
     */
    public function start(Payment $payment): array;

    /**
     * Interroge l'agrégateur : true = payé, false = échoué / expiré, null = toujours en attente.
     * C'est la seule source de vérité : les webhooks ne font que déclencher cette vérification.
     */
    public function check(Payment $payment): ?bool;
}
