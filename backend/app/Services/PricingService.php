<?php

namespace App\Services;

use App\Enums\DeliveryType;
use App\Models\Setting;

class PricingService
{
    /** Coefficient appliqué à la distance à vol d'oiseau pour estimer la distance routière. */
    private const ROAD_FACTOR = 1.3;

    public function distanceKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadiusKm = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return round($earthRadiusKm * 2 * atan2(sqrt($a), sqrt(1 - $a)) * self::ROAD_FACTOR, 2);
    }

    /** Frais de livraison en FCFA, arrondis à la cinquantaine supérieure. */
    public function fee(DeliveryType $type, float $distanceKm): int
    {
        $fee = Setting::int('base_fee') + $distanceKm * Setting::int('per_km_fee');

        if ($type === DeliveryType::Express) {
            $fee += Setting::int('express_fee');
        }

        $fee = max($fee, Setting::int('min_fee'));

        return (int) (ceil($fee / 50) * 50);
    }

    /** @return array{distance_km: float, delivery_fee: int} */
    public function quote(DeliveryType $type, float $pickupLat, float $pickupLng, float $dropoffLat, float $dropoffLng): array
    {
        $distance = $this->distanceKm($pickupLat, $pickupLng, $dropoffLat, $dropoffLng);

        return ['distance_km' => $distance, 'delivery_fee' => $this->fee($type, $distance)];
    }
}
