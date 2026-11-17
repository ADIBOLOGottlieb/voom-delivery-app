<?php

namespace App\Http\Controllers;

use App\Models\Media;
use App\Models\Payment;
use App\Models\Delivery;
use Illuminate\Http\Response;

/** Sert une image stockée en base (photo de profil, article, chat) par son UUID. */
class MediaController extends Controller
{
    public function show(string $uuid): Response
    {
        $media = Media::where('uuid', $uuid)->firstOrFail();

        // Les captures de paiement ne sont visibles que dans le panneau admin (route admin.payments.screenshot).
        abort_if(Payment::where('screenshot_media_id', $media->id)->exists(), 404);

        // Une signature de remise ne doit être visible qu'au client, au livreur assigné ou à l'agence.
        if ($delivery = Delivery::where('signature_media_id', $media->id)->first()) {
            $user = request()->user();
            abort_unless($user && ($user->isAdmin() || $delivery->client_id === $user->id || $delivery->courier_id === $user->id), 404);
        }

        return response($media->bytes(), 200, [
            'Content-Type' => $media->mime,
            'Cache-Control' => 'public, max-age=31536000, immutable',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }
}
