<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\ChatMessage */
class ChatMessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $clientId = $this->resource->request?->client_id;

        return [
            'id' => $this->id,
            // client | agency | system
            'from' => match (true) {
                $this->sender_id === null => 'system',
                $this->sender_id === $clientId => 'client',
                default => 'agency',
            },
            'body' => $this->body,
            'photo_url' => $this->media?->url(),
            'lat' => $this->lat,
            'lng' => $this->lng,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
