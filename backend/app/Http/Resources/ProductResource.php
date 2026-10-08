<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Product */
class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'category' => $this->category,
            'subcategory_id' => $this->subcategory_id,
            'type' => $this->type,
            'name' => $this->name,
            'description' => $this->description,
            'price' => $this->price,
            'unit' => $this->unit,
            'image_url' => $this->imageUrl(),
            'vendor_name' => $this->vendor_name,
            'pickup_address' => $this->pickup_address,
            // Contenu d'un pack (vide pour un produit simple).
            'items' => $this->whenLoaded('packItems', fn () => $this->packItems->map(fn ($item) => [
                'name' => $item->name,
                'quantity' => $item->pivot->quantity,
                'unit' => $item->unit,
            ])->values(), []),
        ];
    }
}
