<?php

namespace App\Enums;

enum PaymentMethod: string
{
    case Flooz = 'flooz';
    case Mixx = 'mixx';

    public function label(): string
    {
        return match ($this) {
            self::Flooz => 'Flooz (Moov Africa)',
            self::Mixx => 'Mixx by Yas',
        };
    }
}
