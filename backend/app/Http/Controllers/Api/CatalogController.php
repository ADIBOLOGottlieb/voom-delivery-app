<?php

namespace App\Http\Controllers\Api;

use App\Enums\PaymentMethod;
use App\Http\Controllers\Controller;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use App\Models\Setting;
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

    /** Comptes marchands de l'agence pour le paiement mobile money. */
    public function paymentInfo(): JsonResponse
    {
        $methods = [];
        foreach (PaymentMethod::cases() as $method) {
            $number = Setting::get("{$method->value}_merchant_number");
            if ($number) {
                $methods[] = ['method' => $method->value, 'label' => $method->label(), 'merchant_number' => $number];
            }
        }

        return response()->json([
            'merchant_name' => Setting::get('merchant_name'),
            'instructions' => Setting::get('payment_instructions'),
            'methods' => $methods,
        ]);
    }
}
