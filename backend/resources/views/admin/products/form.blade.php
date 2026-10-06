@extends('layouts.admin')

@section('title', $product->exists ? 'Modifier le produit' : 'Nouveau produit')

@section('content')
    <a href="{{ route('admin.products.index') }}" class="text-gray-500">← Marketplace</a>
    <h1 class="text-2xl font-bold mt-2 mb-4">{{ $product->exists ? 'Modifier '.$product->name : 'Nouveau produit' }}</h1>

    <form method="POST" enctype="multipart/form-data"
          action="{{ $product->exists ? route('admin.products.update', $product) : route('admin.products.store') }}"
          class="bg-white rounded-lg shadow-sm p-6 max-w-2xl space-y-4">
        @csrf
        @if ($product->exists) @method('PUT') @endif

        <div class="grid grid-cols-2 gap-4">
            <div>
                <label class="block text-sm font-medium mb-1">Catégorie</label>
                <select name="category" class="w-full border rounded px-3 py-2">
                    @foreach (\App\Models\Product::CATEGORIES as $key => $label)
                        <option value="{{ $key }}" @selected(old('category', $product->category) === $key)>{{ $label }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="block text-sm font-medium mb-1">Nom</label>
                <input name="name" value="{{ old('name', $product->name) }}" required class="w-full border rounded px-3 py-2">
            </div>
            <div>
                <label class="block text-sm font-medium mb-1">Prix (FCFA)</label>
                <input name="price" type="number" min="0" value="{{ old('price', $product->price) }}" required class="w-full border rounded px-3 py-2">
            </div>
            <div>
                <label class="block text-sm font-medium mb-1">Unité (ex. kg, pièce)</label>
                <input name="unit" value="{{ old('unit', $product->unit) }}" class="w-full border rounded px-3 py-2">
            </div>
        </div>

        <div>
            <label class="block text-sm font-medium mb-1">Description</label>
            <textarea name="description" rows="3" class="w-full border rounded px-3 py-2">{{ old('description', $product->description) }}</textarea>
        </div>

        <fieldset class="border rounded p-4 space-y-3">
            <legend class="px-1 text-sm font-semibold">Vendeur & point de récupération (point A)</legend>
            <div>
                <label class="block text-sm font-medium mb-1">Nom du vendeur</label>
                <input name="vendor_name" value="{{ old('vendor_name', $product->vendor_name) }}" class="w-full border rounded px-3 py-2">
            </div>
            <div>
                <label class="block text-sm font-medium mb-1">Adresse de récupération</label>
                <input name="pickup_address" value="{{ old('pickup_address', $product->pickup_address) }}" required class="w-full border rounded px-3 py-2">
            </div>
            <div class="grid grid-cols-2 gap-4">
                <div>
                    <label class="block text-sm font-medium mb-1">Latitude</label>
                    <input name="pickup_lat" value="{{ old('pickup_lat', $product->pickup_lat) }}" required class="w-full border rounded px-3 py-2" placeholder="6.1319">
                </div>
                <div>
                    <label class="block text-sm font-medium mb-1">Longitude</label>
                    <input name="pickup_lng" value="{{ old('pickup_lng', $product->pickup_lng) }}" required class="w-full border rounded px-3 py-2" placeholder="1.2228">
                </div>
            </div>
            <p class="text-xs text-gray-500">Astuce : dans Google Maps, faites un clic droit sur l'emplacement puis cliquez sur les coordonnées pour les copier.</p>
        </fieldset>

        <div>
            <label class="block text-sm font-medium mb-1">Photo</label>
            @if ($product->imageUrl())
                <img src="{{ $product->imageUrl() }}" alt="" class="h-24 rounded mb-2">
            @endif
            <input type="file" name="image" accept="image/*">
        </div>

        <label class="flex items-center gap-2">
            <input type="checkbox" name="is_active" value="1" @checked(old('is_active', $product->is_active))>
            Visible dans l'application
        </label>

        <button class="bg-black text-voom font-semibold rounded px-6 py-2">Enregistrer</button>
    </form>
@endsection
