<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ChatMessageResource;
use App\Http\Resources\DeliveryRequestResource;
use App\Models\DeliveryRequest;
use App\Models\Media;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Demandes rapides des clients habitués : photos des articles + chat avec l'agence,
 * qui programme ensuite la livraison depuis le panneau admin.
 */
class RequestController extends Controller
{
    private const MAX_PHOTOS = 6;

    public function index(Request $request): AnonymousResourceCollection
    {
        $requests = $request->user()->deliveryRequests()
            ->with(['latestMessage.media', 'delivery'])
            ->orderByDesc('last_message_at')
            ->paginate(30);

        return DeliveryRequestResource::collection($requests);
    }

    public function store(Request $request): JsonResponse
    {
        $client = $request->user();
        if (! $client->isRegularClient()) {
            throw ValidationException::withMessages([
                'photos' => 'La commande par photos est réservée aux clients habitués. Utilisez le formulaire de livraison.',
            ]);
        }

        $data = $request->validate([
            'message' => ['nullable', 'string', 'max:2000'],
            'photos' => ['required_without:message', 'array', 'max:'.self::MAX_PHOTOS],
            'photos.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $deliveryRequest = DB::transaction(function () use ($client, $data, $request) {
            $deliveryRequest = $client->deliveryRequests()->create();

            foreach ($request->file('photos', []) as $photo) {
                $deliveryRequest->post($client, ['media_id' => Media::fromUpload($photo)->id]);
            }
            if (! empty($data['message'])) {
                $deliveryRequest->post($client, ['body' => $data['message']]);
            }
            $deliveryRequest->post(null, [
                'body' => "Demande reçue ✅ L'agence vous répond ici pour programmer la livraison.",
            ]);

            return $deliveryRequest;
        });

        return (new DeliveryRequestResource($deliveryRequest->load(['messages.media', 'delivery'])))
            ->response()
            ->setStatusCode(201);
    }

    /** Ouvre la discussion (et la marque comme lue par le client). */
    public function show(Request $request, DeliveryRequest $deliveryRequest): DeliveryRequestResource
    {
        $this->authorizeOwner($request, $deliveryRequest);

        $deliveryRequest->markReadByClient();

        return new DeliveryRequestResource($deliveryRequest->load(['messages.media', 'delivery']));
    }

    /** Message texte, photo ou position. */
    public function message(Request $request, DeliveryRequest $deliveryRequest): JsonResponse
    {
        $this->authorizeOwner($request, $deliveryRequest);

        $data = $request->validate([
            'body' => ['nullable', 'string', 'max:2000'],
            'photo' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'lat' => ['nullable', 'required_with:lng', 'numeric', 'between:-90,90'],
            'lng' => ['nullable', 'required_with:lat', 'numeric', 'between:-180,180'],
        ]);

        if (empty($data['body']) && ! $request->hasFile('photo') && ! isset($data['lat'])) {
            throw ValidationException::withMessages(['body' => 'Message vide.']);
        }

        $message = $deliveryRequest->post($request->user(), [
            'body' => $data['body'] ?? null,
            'media_id' => $request->hasFile('photo') ? Media::fromUpload($request->file('photo'))->id : null,
            'lat' => $data['lat'] ?? null,
            'lng' => $data['lng'] ?? null,
        ]);

        // Un nouveau message rouvre une demande clôturée.
        if ($deliveryRequest->status === DeliveryRequest::CLOSED) {
            $deliveryRequest->forceFill(['status' => DeliveryRequest::OPEN])->save();
        }

        return (new ChatMessageResource($message->setRelation('request', $deliveryRequest)->load('media')))
            ->response()
            ->setStatusCode(201);
    }

    private function authorizeOwner(Request $request, DeliveryRequest $deliveryRequest): void
    {
        abort_unless($deliveryRequest->client_id === $request->user()->id, 404);
    }
}
