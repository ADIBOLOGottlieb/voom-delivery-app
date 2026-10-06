<?php

namespace App\Models;

use App\Enums\DeliveryStatus;
use App\Enums\DeliveryType;
use App\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

#[Fillable([
    'client_id', 'product_id', 'quantity', 'type',
    'pickup_address', 'pickup_lat', 'pickup_lng', 'pickup_contact_name', 'pickup_contact_phone',
    'dropoff_address', 'dropoff_lat', 'dropoff_lng', 'recipient_name', 'recipient_phone',
    'package_description', 'notes', 'scheduled_at', 'distance_km', 'delivery_fee',
    'items_amount', 'total_amount',
])]
class Delivery extends Model
{
    protected $attributes = [
        'status' => 'pending',
        'payment_status' => 'unpaid',
        'items_amount' => 0,
    ];

    protected static function booted(): void
    {
        static::creating(function (Delivery $delivery) {
            $delivery->reference ??= static::generateReference();
        });
    }

    public static function generateReference(): string
    {
        do {
            $reference = 'VD-'.strtoupper(Str::random(6));
        } while (static::where('reference', $reference)->exists());

        return $reference;
    }

    protected function casts(): array
    {
        return [
            'type' => DeliveryType::class,
            'status' => DeliveryStatus::class,
            'payment_status' => PaymentStatus::class,
            'pickup_lat' => 'float',
            'pickup_lng' => 'float',
            'dropoff_lat' => 'float',
            'dropoff_lng' => 'float',
            'distance_km' => 'float',
            'delivery_fee' => 'integer',
            'items_amount' => 'integer',
            'total_amount' => 'integer',
            'quantity' => 'integer',
            'scheduled_at' => 'datetime',
            'assigned_at' => 'datetime',
            'picked_up_at' => 'datetime',
            'delivered_at' => 'datetime',
            'cancelled_at' => 'datetime',
        ];
    }

    public function client(): BelongsTo
    {
        return $this->belongsTo(User::class, 'client_id');
    }

    public function courier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'courier_id');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class)->latest('id');
    }

    public function latestPayment(): HasOne
    {
        return $this->hasOne(Payment::class)->latestOfMany();
    }

    // --- Règles métier -------------------------------------------------------

    public function canSubmitPayment(): bool
    {
        return $this->status !== DeliveryStatus::Cancelled
            && in_array($this->payment_status, [PaymentStatus::Unpaid, PaymentStatus::Rejected], true);
    }

    public function canBeCancelledByClient(): bool
    {
        return $this->status === DeliveryStatus::Pending
            && $this->payment_status !== PaymentStatus::Verified;
    }

    public function canBeAssigned(): bool
    {
        return in_array($this->status, [DeliveryStatus::Pending, DeliveryStatus::Assigned], true)
            && $this->payment_status === PaymentStatus::Verified;
    }

    public function assignTo(User $courier): void
    {
        if (! $courier->isCourier() || ! $courier->is_active) {
            throw ValidationException::withMessages(['courier_id' => "Ce compte n'est pas un livreur actif."]);
        }
        if (! $this->canBeAssigned()) {
            throw ValidationException::withMessages([
                'courier_id' => 'Le paiement doit être confirmé et le colis pas encore récupéré pour assigner un livreur.',
            ]);
        }

        $this->forceFill([
            'courier_id' => $courier->id,
            'status' => DeliveryStatus::Assigned,
            'assigned_at' => now(),
        ])->save();
    }

    /** Transition effectuée par le livreur : assigned -> picked_up -> delivered. */
    public function advanceByCourier(DeliveryStatus $target): void
    {
        $allowed = match ($this->status) {
            DeliveryStatus::Assigned => DeliveryStatus::PickedUp,
            DeliveryStatus::PickedUp => DeliveryStatus::Delivered,
            default => null,
        };

        if ($allowed !== $target) {
            throw ValidationException::withMessages([
                'status' => "Transition impossible : {$this->status->label()} → {$target->label()}.",
            ]);
        }

        $this->status = $target;
        if ($target === DeliveryStatus::PickedUp) {
            $this->picked_up_at = now();
        } else {
            $this->delivered_at = now();
        }
        $this->save();
    }

    public function cancel(?string $reason = null): void
    {
        if ($this->status->isFinal()) {
            throw ValidationException::withMessages(['status' => 'Cette livraison est déjà terminée.']);
        }

        $this->forceFill([
            'status' => DeliveryStatus::Cancelled,
            'cancelled_at' => now(),
            'cancel_reason' => $reason,
        ])->save();
    }
}
