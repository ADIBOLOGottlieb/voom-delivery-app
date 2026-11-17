<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['delivery_id', 'client_id', 'courier_id', 'rating', 'comment'])]
class CourierReview extends Model
{
    protected function casts(): array { return ['rating' => 'integer']; }
    public function delivery(): BelongsTo { return $this->belongsTo(Delivery::class); }
    public function courier(): BelongsTo { return $this->belongsTo(User::class, 'courier_id'); }
    public function client(): BelongsTo { return $this->belongsTo(User::class, 'client_id'); }
}
