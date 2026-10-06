<?php

namespace App\Enums;

enum Role: string
{
    case Client = 'client';
    case Courier = 'livreur';
    case Admin = 'admin';

    public function label(): string
    {
        return match ($this) {
            self::Client => 'Client',
            self::Courier => 'Livreur',
            self::Admin => 'Administrateur',
        };
    }
}
