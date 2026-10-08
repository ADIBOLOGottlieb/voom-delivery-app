<?php

namespace App\Services;

use App\Enums\DeliveryStatus;
use App\Enums\DeliveryType;
use App\Models\Delivery;

/** Notifications aux livreurs : nouvelle course et rappels pour les livraisons urgentes. */
class DeliveryReminder
{
    /** Une livraison dont l'heure limite tombe dans ce délai est considérée urgente. */
    public const URGENT_WITHIN_MINUTES = 45;

    /** Intervalle minimal entre deux rappels pour une même livraison. */
    public const REMIND_EVERY_MINUTES = 10;

    public function __construct(private readonly PushNotifier $push) {}

    public static function isUrgent(Delivery $delivery): bool
    {
        return $delivery->type === DeliveryType::Express
            || ($delivery->deadline_at && $delivery->deadline_at->lte(now()->addMinutes(self::URGENT_WITHIN_MINUTES)));
    }

    public function notifyAssigned(Delivery $delivery): void
    {
        $courier = $delivery->courier;
        if (! $courier) {
            return;
        }

        $urgent = self::isUrgent($delivery);
        $this->push->toUser(
            $courier,
            ($urgent ? '⚡ URGENT · ' : '').'Nouvelle livraison '.$delivery->reference,
            'Récupération : '.$delivery->pickup_address.$this->deadlineText($delivery),
            ['delivery_id' => (string) $delivery->id, 'kind' => 'assigned'],
            $urgent,
        );
    }

    /**
     * Rappels pour les livraisons urgentes en cours (Express ou heure limite proche/dépassée).
     *
     * @return int nombre de rappels envoyés
     */
    public function sendDueReminders(): int
    {
        $sent = 0;

        Delivery::query()
            ->with('courier')
            ->whereIn('status', [DeliveryStatus::Assigned, DeliveryStatus::PickedUp])
            ->whereNotNull('courier_id')
            ->where(fn ($q) => $q
                ->where('type', DeliveryType::Express)
                ->orWhere('deadline_at', '<=', now()->addMinutes(self::URGENT_WITHIN_MINUTES)))
            ->where(fn ($q) => $q
                ->whereNull('last_reminder_at')
                ->orWhere('last_reminder_at', '<=', now()->subMinutes(self::REMIND_EVERY_MINUTES)))
            ->each(function (Delivery $delivery) use (&$sent) {
                $late = $delivery->deadline_at?->isPast();
                $step = $delivery->status === DeliveryStatus::Assigned ? 'Colis à récupérer' : 'Colis à livrer';

                $ok = $this->push->toUser(
                    $delivery->courier,
                    ($late ? '⏰ EN RETARD · ' : '⚡ Urgent · ').$delivery->reference,
                    $step.' : '.($delivery->status === DeliveryStatus::Assigned ? $delivery->pickup_address : $delivery->dropoff_address)
                        .$this->deadlineText($delivery),
                    ['delivery_id' => (string) $delivery->id, 'kind' => 'reminder'],
                    true,
                );

                $delivery->forceFill(['last_reminder_at' => now()])->saveQuietly();
                $sent += $ok ? 1 : 0;
            });

        return $sent;
    }

    private function deadlineText(Delivery $delivery): string
    {
        return $delivery->deadline_at
            ? ' · avant '.$delivery->deadline_at->timezone(config('app.timezone'))->format('H:i')
            : '';
    }
}
