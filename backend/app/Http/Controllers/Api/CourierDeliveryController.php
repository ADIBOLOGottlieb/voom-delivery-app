<?php

namespace App\Http\Controllers\Api;

use App\Enums\DeliveryStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\DeliveryResource;
use App\Models\Delivery;
use App\Models\Media;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use App\Services\DeliveryReminder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/** Livraisons assignées au livreur connecté. */
class CourierDeliveryController extends Controller
{
    private const RELATIONS = ['client', 'product', 'photos', 'deliveryRequest', 'signature'];

    /** ?scope=active (par défaut : assignées / récupérées) ou ?scope=history (terminées). */
    public function index(Request $request): AnonymousResourceCollection
    {
        $active = [DeliveryStatus::Assigned, DeliveryStatus::PickedUp];

        $query = $request->user()->assignedDeliveries()->with(self::RELATIONS);

        if ($request->query('scope') === 'history') {
            $query->whereNotIn('status', $active)->latest('updated_at');
        } else {
            $query->whereIn('status', $active)->orderBy('assigned_at');
        }

        return DeliveryResource::collection($query->paginate(30));
    }

    public function show(Request $request, Delivery $delivery): DeliveryResource
    {
        $this->authorizeCourier($request, $delivery);

        return new DeliveryResource($delivery->load(self::RELATIONS));
    }

    public function updateStatus(Request $request, Delivery $delivery): DeliveryResource
    {
        $this->authorizeCourier($request, $delivery);

        $data = $request->validate([
            'status' => ['required', Rule::in([DeliveryStatus::PickedUp->value, DeliveryStatus::Delivered->value])],
            'note' => ['nullable', 'string', 'max:1000'],
            'signature' => ['nullable', 'string', 'max:1000000'],
        ]);

        $target = DeliveryStatus::from($data['status']);
        if ($target === DeliveryStatus::Delivered && empty($data['signature'])) {
            throw ValidationException::withMessages(['signature' => 'La signature du destinataire est obligatoire.']);
        }
        if ($target !== DeliveryStatus::Delivered && ! empty($data['signature'])) {
            throw ValidationException::withMessages(['signature' => 'La signature est enregistrée au moment de la remise du colis.']);
        }
        if (! empty($data['signature'])) {
            $encoded = preg_replace('#^data:image/png;base64,#', '', $data['signature']);
            $bytes = base64_decode($encoded, true);
            abort_if($bytes === false || strlen($bytes) > 700_000, 422, 'Signature invalide ou trop volumineuse.');
            $image = getimagesizefromstring($bytes);
            abort_if(! $image || $image[2] !== IMAGETYPE_PNG, 422, 'La signature PNG est invalide.');
            $media = new Media;
            $media->uuid = (string) Str::uuid();
            $media->mime = 'image/png';
            $media->size = strlen($bytes);
            $media->data = base64_encode($bytes);
            DB::transaction(function () use ($media, $delivery, $target, $request, $data) {
                $media->save();
                $delivery->advanceByCourier($target, $request->user());
                $delivery->forceFill(['signature_media_id' => $media->id, 'signed_at' => now()])->save();
                $delivery->appendCourierNote($data['note'] ?? null);
            });
        } else {
            $delivery->advanceByCourier($target, $request->user());
            $delivery->appendCourierNote($data['note'] ?? null);
        }
        app(DeliveryReminder::class)->notifyClient($delivery, $target === DeliveryStatus::PickedUp ? 'picked_up' : 'delivered');

        return new DeliveryResource($delivery->load(self::RELATIONS));
    }

    public function cancel(Request $request, Delivery $delivery): DeliveryResource
    {
        $this->authorizeCourier($request, $delivery);
        $data = $request->validate(['reason' => ['required', 'string', 'max:255'], 'note' => ['nullable', 'string', 'max:1000']]);
        $delivery->cancelByCourier($data['reason'], $data['note'] ?? null);
        $delivery->load('client');
        app(DeliveryReminder::class)->notifyClient($delivery, 'cancelled', $data['reason']);
        return new DeliveryResource($delivery->load(self::RELATIONS));
    }

    public function location(Request $request)
    {
        $data = $request->validate(['lat' => ['required', 'numeric', 'between:-90,90'], 'lng' => ['required', 'numeric', 'between:-180,180']]);
        $request->user()->forceFill(['last_lat' => $data['lat'], 'last_lng' => $data['lng'], 'location_updated_at' => now()])->save();
        return response()->json(['updated_at' => now()->toIso8601String()]);
    }

    private function authorizeCourier(Request $request, Delivery $delivery): void
    {
        abort_unless($delivery->courier_id === $request->user()->id, 404);
    }
}
