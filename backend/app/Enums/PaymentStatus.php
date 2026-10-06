<?php

namespace App\Enums;

/**
 * Statut de paiement d'une livraison et d'une tentative de paiement.
 *
 * Livraison : unpaid -> verified (agrégateur) ; en mode manuel : unpaid -> submitted -> verified | rejected.
 * Tentative via agrégateur : pending -> verified | failed.
 */
enum PaymentStatus: string
{
    case Unpaid = 'unpaid';
    case Pending = 'pending';
    case Submitted = 'submitted';
    case Verified = 'verified';
    case Rejected = 'rejected';
    case Failed = 'failed';

    public function label(): string
    {
        return match ($this) {
            self::Unpaid => 'Non payé',
            self::Pending => 'Paiement en cours',
            self::Submitted => 'Preuve envoyée',
            self::Verified => 'Paiement confirmé',
            self::Rejected => 'Paiement refusé',
            self::Failed => 'Paiement échoué',
        };
    }

    /** Classes Tailwind du badge affiché dans le panneau admin. */
    public function badgeClass(): string
    {
        return match ($this) {
            self::Unpaid => 'bg-gray-200 text-gray-800',
            self::Pending, self::Submitted => 'bg-orange-100 text-orange-800',
            self::Verified => 'bg-green-100 text-green-800',
            self::Rejected, self::Failed => 'bg-red-100 text-red-800',
        };
    }
}
