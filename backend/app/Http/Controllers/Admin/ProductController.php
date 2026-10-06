<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

/** Gestion de la marketplace (Shopping & Agroalimentaire). */
class ProductController extends Controller
{
    public function index(Request $request): View
    {
        $category = $request->query('category');

        $products = Product::query()
            ->when(array_key_exists((string) $category, Product::CATEGORIES), fn ($q) => $q->where('category', $category))
            ->latest()
            ->paginate(25)
            ->withQueryString();

        return view('admin.products.index', compact('products', 'category'));
    }

    public function create(): View
    {
        return view('admin.products.form', ['product' => new Product(['is_active' => true, 'category' => 'shopping'])]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validated($request);
        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('products', 'public');
        }

        Product::create($data);

        return redirect()->route('admin.products.index')->with('success', 'Produit ajouté.');
    }

    public function edit(Product $product): View
    {
        return view('admin.products.form', compact('product'));
    }

    public function update(Request $request, Product $product): RedirectResponse
    {
        $data = $this->validated($request);
        if ($request->hasFile('image')) {
            if ($product->image_path) {
                Storage::disk('public')->delete($product->image_path);
            }
            $data['image_path'] = $request->file('image')->store('products', 'public');
        }

        $product->update($data);

        return redirect()->route('admin.products.index')->with('success', 'Produit mis à jour.');
    }

    public function destroy(Product $product): RedirectResponse
    {
        // Les produits déjà commandés restent liés aux livraisons : on les désactive plutôt que de les supprimer.
        if ($product->getConnection()->table('deliveries')->where('product_id', $product->id)->exists()) {
            $product->update(['is_active' => false]);

            return back()->with('success', 'Produit déjà commandé : il a été désactivé au lieu d\'être supprimé.');
        }

        if ($product->image_path) {
            Storage::disk('public')->delete($product->image_path);
        }
        $product->delete();

        return back()->with('success', 'Produit supprimé.');
    }

    /** @return array<string, mixed> */
    private function validated(Request $request): array
    {
        $data = $request->validate([
            'category' => ['required', Rule::in(array_keys(Product::CATEGORIES))],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'price' => ['required', 'integer', 'min:0'],
            'unit' => ['nullable', 'string', 'max:30'],
            'vendor_name' => ['nullable', 'string', 'max:255'],
            'pickup_address' => ['required', 'string', 'max:255'],
            'pickup_lat' => ['required', 'numeric', 'between:-90,90'],
            'pickup_lng' => ['required', 'numeric', 'between:-180,180'],
            'image' => ['nullable', 'image', 'max:4096'],
        ]);
        unset($data['image']);

        return [...$data, 'is_active' => $request->boolean('is_active')];
    }
}
