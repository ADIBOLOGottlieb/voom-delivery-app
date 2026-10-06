<?php

namespace App\Enums;

enum DeliveryType: string
{
    case Plis = 'plis';
    case Colis = 'colis';
    case Express = 'express';
    case Programmee = 'programmee';

    public function label(): string
    {
        return match ($this) {
            self::Plis => 'Plis',
            self::Colis => 'Colis',
            self::Express => 'Express',
            self::Programmee => 'Programmée',
        };
    }
}
