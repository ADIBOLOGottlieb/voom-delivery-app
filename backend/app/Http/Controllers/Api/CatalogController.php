<?php

namespace App\Http\Controllers\Api;

use App\Enums\PaymentMethod;
use App\Http\Controllers\Controller;
use App\Http\Resources\ProductResource;
use App\Http\Resources\PromotionResource;
use App\Models\Product;
use App\Models\Promotion;
use App\Models\Setting;
use App\Models\Subcategory;
use App\Services\Payments\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class CatalogController extends Controller
{
    /** Produits et packs de la marketplace (gérés par l'admin). */
    public function products(Request $request): AnonymousResourceCollection
    {
        $data = $request->validate([
            'category' => ['nullable', Rule::in(array_keys(Product::CATEGORIES))],
            'subcategory_id' => ['nullable', 'integer'],
            'type' => ['nullable', Rule::in(['product', 'pack'])],
            'search' => ['nullable', 'string', 'max:100'],
        ]);

        $products = Product::query()
            ->with('packItems')
            ->where('is_active', true)
            ->when($data['category'] ?? null, fn ($q, $c) => $q->where('category', $c))
            ->when($data['subcategory_id'] ?? null, fn ($q, $s) => $q->where('subcategory_id', $s))
            ->when($data['type'] ?? null, fn ($q, $t) => $q->where('type', $t))
            ->when($data['search'] ?? null, fn ($q, $s) => $q->where('name', 'like', "%{$s}%"))
            ->orderByRaw("case when type = 'pack' then 0 else 1 end")
            ->orderBy('name')
            ->paginate(100);

        return ProductResource::collection($products);
    }

    /** Sous-catégories (onglets verticaux) d'une catégorie, dans l'ordre choisi par l'admin. */
    public function subcategories(Request $request): JsonResponse
    {
        $category = $request->validate(['category' => ['required', Rule::in(array_keys(Product::CATEGORIES))]])['category'];

        return response()->json([
            'data' => Subcategory::where('category', $category)->orderBy('position')->orderBy('id')->get(['id', 'name']),
            'has_packs' => Product::where('category', $category)->where('type', 'pack')->where('is_active', true)->exists(),
        ]);
    }

    /** Annonces promo visibles (bandeau défilant de l'accueil). */
    public function promotions(): AnonymousResourceCollection
    {
        return PromotionResource::collection(Promotion::visible()->with('product.packItems')->latest()->limit(10)->get());
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
