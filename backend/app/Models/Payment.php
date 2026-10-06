<?php

namespace App\Models;

use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'delivery_id', 'method', 'transaction_ref', 'payer_phone', 'amount',
    'screenshot_path', 'status', 'reviewed_by', 'reviewed_at', 'rejection_reason',
    'gateway', 'gateway_reference', 'checkout_token',
])]
class Payment extends Model
{
    /** Paiement traité par un agrégateur (KKiaPay, PayGate) plutôt que par capture d'écran. */
    public function isGateway(): bool
    {
        return $this->gateway !== null;
    }

    protected function casts(): array
    {
        return [
            'method' => PaymentMethod::class,
            'status' => PaymentStatus::class,
            'amount' => 'integer',
            'reviewed_at' => 'datetime',
        ];
    }

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
