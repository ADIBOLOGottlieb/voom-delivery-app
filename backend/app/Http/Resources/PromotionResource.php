<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Promotion */
class PromotionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'body' => $this->body,
            'image_url' => $this->imageUrl(),
            'product' => $this->product && $this->product->is_active ? new ProductResource($this->product) : null,
            'ends_at' => $this->ends_at?->toIso8601String(),
        ];
    }
}
