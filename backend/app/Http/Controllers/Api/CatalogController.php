<?php

namespace App\Http\Controllers\Api;

use App\Enums\PaymentMethod;
use App\Http\Controllers\Controller;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use App\Models\Setting;
use App\Services\Payments\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class CatalogController extends Controller
{
    /** Produits de la marketplace (gérés par l'admin). */
    public function products(Request $request): AnonymousResourceCollection
    {
        $data = $request->validate([
            'category' => ['nullable', Rule::in(array_keys(Product::CATEGORIES))],
            'search' => ['nullable', 'string', 'max:100'],
        ]);

        $products = Product::query()
            ->where('is_active', true)
            ->when($data['category'] ?? null, fn ($q, $c) => $q->where('category', $c))
            ->when($data['search'] ?? null, fn ($q, $s) => $q->where('name', 'like', "%{$s}%"))
            ->latest()
            ->paginate(40);

        return ProductResource::collection($products);
    }

    /**
     * Mode de paiement proposé à l'app :
     * - gateway : paiement automatique via l'agrégateur (Flooz et Mixx toujours proposés) ;
     * - manual  : virement sur les numéros marchands + capture d'écran.
     */
    public function paymentInfo(PaymentService $payments): JsonResponse
    {
        $gateway = $payments->gateway();

        $methods = [];
        foreach (PaymentMethod::cases() as $method) {
            $number = Setting::get("{$method->value}_merchant_number");
            if ($gateway || $number) {
                $methods[] = ['method' => $method->value, 'label' => $method->label(), 'merchant_number' => $number ?: null];
            }
        }

        return response()->json([
            'mode' => $gateway ? 'gateway' : 'manual',
            'gateway' => $gateway?->name(),
            'fee_note' => $gateway?->name() === 'kkiapay' ? config('payments.kkiapay.fee_label') : null,
            'merchant_name' => Setting::get('merchant_name'),
            'instructions' => Setting::get('payment_instructions'),
            'methods' => $methods,
        ]);
    }
}
