<?php

namespace App\Http\Controllers\Api;

use App\Enums\DeliveryType;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\DeliveryResource;
use App\Models\Delivery;
use App\Models\Payment;
use App\Models\Product;
use App\Services\PricingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/** Demandes de livraison côté client. */
class DeliveryController extends Controller
{
    private const RELATIONS = ['courier', 'client', 'product', 'latestPayment'];

    public function __construct(private readonly PricingService $pricing) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $deliveries = $request->user()->deliveries()
            ->with(self::RELATIONS)
            ->latest()
            ->paginate(20);

        return DeliveryResource::collection($deliveries);
    }

    public function quote(Request $request): JsonResponse
    {
        $data = $request->validate([
            'type' => ['required', Rule::enum(DeliveryType::class)],
            ...$this->coordinateRules(),
        ]);

        return response()->json($this->pricing->quote(
            DeliveryType::from($data['type']),
            $data['pickup_lat'], $data['pickup_lng'], $data['dropoff_lat'], $data['dropoff_lng'],
        ));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'type' => ['required', Rule::enum(DeliveryType::class)],
            'product_id' => ['nullable', Rule::exists('products', 'id')->where('is_active', true)],
            'quantity' => ['required_with:product_id', 'nullable', 'integer', 'min:1', 'max:100'],
            'pickup_address' => ['required_without:product_id', 'nullable', 'string', 'max:255'],
            'pickup_contact_name' => ['nullable', 'string', 'max:255'],
            'pickup_contact_phone' => ['nullable', 'string', 'max:30'],
            'dropoff_address' => ['required', 'string', 'max:255'],
            'recipient_name' => ['required', 'string', 'max:255'],
            'recipient_phone' => ['required', 'string', 'max:30'],
            'package_description' => ['nullable', 'string', 'max:1000'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'scheduled_at' => ['nullable', 'required_if:type,programmee', 'date', 'after:now'],
            // Heure limite de livraison choisie par le client (au moins 30 min pour laisser le temps au livreur).
            'deadline_at' => ['nullable', 'date', 'after:'.now()->addMinutes(29)->toIso8601String()],
            ...$this->coordinateRules(pickupRequired: ! $request->filled('product_id')),
        ]);

        $type = DeliveryType::from($data['type']);
        $itemsAmount = 0;

        // Commande marketplace : le point A est l'adresse du vendeur définie par l'admin.
        if (! empty($data['product_id'])) {
            $product = Product::findOrFail($data['product_id']);
            $data['pickup_address'] = $product->pickup_address;
            $data['pickup_lat'] = $product->pickup_lat;
            $data['pickup_lng'] = $product->pickup_lng;
            $data['pickup_contact_name'] = $product->vendor_name;
            $data['package_description'] ??= "{$data['quantity']} × {$product->name}";
            $itemsAmount = $product->price * $data['quantity'];
        }

        $quote = $this->pricing->quote($type, $data['pickup_lat'], $data['pickup_lng'], $data['dropoff_lat'], $data['dropoff_lng']);

        $delivery = $request->user()->deliveries()->create([
            ...$data,
            ...$quote,
            'items_amount' => $itemsAmount,
            'total_amount' => $quote['delivery_fee'] + $itemsAmount,
        ]);

        return (new DeliveryResource($delivery->load(self::RELATIONS)))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, Delivery $delivery): DeliveryResource
    {
        $this->authorizeOwner($request, $delivery);

        return new DeliveryResource($delivery->load(self::RELATIONS));
    }

    public function cancel(Request $request, Delivery $delivery): DeliveryResource
    {
        $this->authorizeOwner($request, $delivery);

        if (! $delivery->canBeCancelledByClient()) {
            throw ValidationException::withMessages([
                'status' => "Cette livraison ne peut plus être annulée depuis l'application. Contactez l'agence.",
            ]);
        }

        $delivery->cancel($request->string('reason')->limit(255)->toString() ?: 'Annulée par le client');

        return new DeliveryResource($delivery->load(self::RELATIONS));
    }

    /** Envoi de la preuve de paiement (capture d'écran Flooz / Mixx by Yas). */
    public function submitPayment(Request $request, Delivery $delivery): DeliveryResource
    {
        $this->authorizeOwner($request, $delivery);

        $data = $request->validate([
            'method' => ['required', Rule::enum(PaymentMethod::class)],
            'transaction_ref' => ['required', 'string', 'max:100'],
            'payer_phone' => ['required', 'string', 'max:30'],
            'screenshot' => ['required', 'image', 'max:5120'],
        ]);

        if (! $delivery->canSubmitPayment()) {
            throw ValidationException::withMessages(['payment' => 'Un paiement est déjà en cours de vérification ou confirmé.']);
        }

        $alreadyUsed = Payment::query()
            ->where('method', $data['method'])
            ->where('transaction_ref', $data['transaction_ref'])
            ->where('status', '!=', PaymentStatus::Rejected)
            ->exists();

        if ($alreadyUsed) {
            throw ValidationException::withMessages(['transaction_ref' => 'Cette référence de transaction a déjà été utilisée.']);
        }

        $path = $request->file('screenshot')->store('payments', 'local');

        DB::transaction(function () use ($delivery, $data, $path) {
            $delivery->payments()->create([
                'method' => $data['method'],
                'transaction_ref' => $data['transaction_ref'],
                'payer_phone' => $data['payer_phone'],
                'amount' => $delivery->total_amount,
                'screenshot_path' => $path,
                'status' => PaymentStatus::Submitted,
            ]);
            $delivery->forceFill(['payment_status' => PaymentStatus::Submitted])->save();
        });

        return new DeliveryResource($delivery->refresh()->load(self::RELATIONS));
    }

    private function authorizeOwner(Request $request, Delivery $delivery): void
    {
        abort_unless($delivery->client_id === $request->user()->id, 404);
    }

    /** @return array<string, array<int, string>> */
    private function coordinateRules(bool $pickupRequired = true): array
    {
        $pickup = $pickupRequired ? 'required' : 'nullable';

        return [
            'pickup_lat' => [$pickup, 'numeric', 'between:-90,90'],
            'pickup_lng' => [$pickup, 'numeric', 'between:-180,180'],
            'dropoff_lat' => ['required', 'numeric', 'between:-90,90'],
            'dropoff_lng' => ['required', 'numeric', 'between:-180,180'],
        ];
    }
}
