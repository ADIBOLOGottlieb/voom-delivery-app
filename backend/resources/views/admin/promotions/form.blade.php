@extends('layouts.admin')

@section('title', $promotion->exists ? 'Modifier l\'annonce' : 'Nouvelle annonce')

@section('content')
    <a href="{{ route('admin.promotions.index') }}" class="text-gray-500">← Annonces</a>
    <h1 class="text-2xl font-bold mt-2 mb-4">{{ $promotion->exists ? 'Modifier l\'annonce' : 'Nouvelle annonce' }}</h1>

    <form method="POST" enctype="multipart/form-data"
          action="{{ $promotion->exists ? route('admin.promotions.update', $promotion) : route('admin.promotions.store') }}"
          class="bg-white rounded-lg shadow-sm p-6 max-w-2xl space-y-4">
        @csrf
        @if ($promotion->exists) @method('PUT') @endif

        <div>
            <label class="block text-sm font-medium mb-1">Titre (court, affiché en gros)</label>
            <input name="title" value="{{ old('title', $promotion->title) }}" required maxlength="80" class="w-full border rounded px-3 py-2"
                   placeholder="-20 % sur les légumes ce week-end">
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Message</label>
            <textarea name="body" rows="2" required maxlength="255" class="w-full border rounded px-3 py-2"
                      placeholder="Commandez avant dimanche, livraison dans tout Lomé.">{{ old('body', $promotion->body) }}</textarea>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Produit ou pack mis en avant (facultatif)</label>
            <select name="product_id" class="w-full border rounded px-3 py-2">
                <option value="">— Aucun —</option>
                @foreach ($products as $product)
                    <option value="{{ $product->id }}" @selected(old('product_id', $promotion->product_id) == $product->id)>
                        {{ $product->type === 'pack' ? '[Pack] ' : '' }}{{ $product->name }}
                    </option>
                @endforeach
            </select>
            <p class="text-xs text-gray-500 mt-1">En touchant le bandeau, le client ouvre directement ce produit.</p>
        </div>
        <div class="grid grid-cols-2 gap-4">
            <div>
                <label class="block text-sm font-medium mb-1">Début (facultatif)</label>
                <input type="datetime-local" name="starts_at" value="{{ old('starts_at', $promotion->starts_at?->format('Y-m-d\TH:i')) }}" class="w-full border rounded px-3 py-2">
            </div>
            <div>
                <label class="block text-sm font-medium mb-1">Fin (facultatif)</label>
                <input type="datetime-local" name="ends_at" value="{{ old('ends_at', $promotion->ends_at?->format('Y-m-d\TH:i')) }}" class="w-full border rounded px-3 py-2">
            </div>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Image du bandeau (format paysage conseillé)</label>
            @if ($promotion->imageUrl())
                <img src="{{ $promotion->imageUrl() }}" alt="" class="h-24 rounded mb-2">
            @endif
            <input type="file" name="image" accept="image/*">
        </div>
        <label class="flex items-center gap-2">
            <input type="checkbox" name="is_active" value="1" @checked(old('is_active', $promotion->is_active))>
            Visible dans l'application
        </label>
        <label class="flex items-center gap-2">
            <input type="checkbox" name="send_push" value="1">
            Envoyer aussi en notification push à tous les clients
        </label>

        <button class="bg-black text-voom font-semibold rounded px-6 py-2">Enregistrer</button>
    </form>
@endsection
