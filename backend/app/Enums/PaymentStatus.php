<?php

namespace App\Enums;

/**
 * Statut de paiement d'une livraison (et d'une preuve de paiement individuelle).
 * Une livraison passe par : unpaid -> submitted -> verified | rejected (-> submitted ...).
 */
enum PaymentStatus: string
{
    case Unpaid = 'unpaid';
    case Submitted = 'submitted';
    case Verified = 'verified';
    case Rejected = 'rejected';

    public function label(): string
    {
        return match ($this) {
            self::Unpaid => 'Non payé',
            self::Submitted => 'Preuve envoyée',
            self::Verified => 'Paiement confirmé',
            self::Rejected => 'Paiement refusé',
        };
    }

    /** Classes Tailwind du badge affiché dans le panneau admin. */
    public function badgeClass(): string
    {
        return match ($this) {
            self::Unpaid => 'bg-gray-200 text-gray-800',
            self::Submitted => 'bg-orange-100 text-orange-800',
            self::Verified => 'bg-green-100 text-green-800',
            self::Rejected => 'bg-red-100 text-red-800',
        };
    }
}
