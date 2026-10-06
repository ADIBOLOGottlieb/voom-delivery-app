<?php

namespace App\Enums;

enum DeliveryStatus: string
{
    case Pending = 'pending';
    case Assigned = 'assigned';
    case PickedUp = 'picked_up';
    case Delivered = 'delivered';
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'En attente',
            self::Assigned => 'Livreur assigné',
            self::PickedUp => 'Colis récupéré',
            self::Delivered => 'Livré',
            self::Cancelled => 'Annulé',
        };
    }

    /** Classes Tailwind du badge affiché dans le panneau admin. */
    public function badgeClass(): string
    {
        return match ($this) {
            self::Pending => 'bg-gray-200 text-gray-800',
            self::Assigned => 'bg-blue-100 text-blue-800',
            self::PickedUp => 'bg-indigo-100 text-indigo-800',
            self::Delivered => 'bg-green-100 text-green-800',
            self::Cancelled => 'bg-red-100 text-red-800',
        };
    }

    public function isFinal(): bool
    {
        return $this === self::Delivered || $this === self::Cancelled;
    }
}
