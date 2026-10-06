<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

#[Fillable([
    'category', 'name', 'description', 'price', 'unit', 'image_path',
    'vendor_name', 'pickup_address', 'pickup_lat', 'pickup_lng', 'is_active',
])]
class Product extends Model
{
    use HasFactory;

    public const CATEGORIES = [
        'shopping' => 'Shopping',
        'agro' => 'Agroalimentaire',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'integer',
            'pickup_lat' => 'float',
            'pickup_lng' => 'float',
            'is_active' => 'boolean',
        ];
    }

    public function imageUrl(): ?string
    {
        return $this->image_path ? Storage::disk('public')->url($this->image_path) : null;
    }
}
