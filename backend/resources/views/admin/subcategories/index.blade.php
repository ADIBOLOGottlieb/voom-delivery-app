@extends('layouts.admin')

@section('title', 'Sous-catégories')

@section('content')
    <h1 class="text-2xl font-bold mb-2">Sous-catégories</h1>
    <p class="text-gray-500 mb-6">Elles apparaissent comme onglets verticaux dans l'app. Modifiez les noms et l'ordre (0 = en haut), puis enregistrez.</p>

    @foreach ($groups as $category => $group)
        <section class="bg-white rounded-lg shadow-sm p-5 mb-6 max-w-3xl">
            <h2 class="font-semibold mb-3">{{ $group['label'] }}</h2>

            @if ($group['items']->isNotEmpty())
                <form method="POST" action="{{ route('admin.subcategories.update') }}" class="space-y-2">
                    @csrf @method('PUT')
                    @foreach ($group['items'] as $item)
                        <div class="flex items-center gap-2">
                            <input type="number" name="items[{{ $item->id }}][position]" value="{{ $item->position }}" min="0"
                                   class="w-20 border rounded px-2 py-2" aria-label="Ordre">
                            <input name="items[{{ $item->id }}][name]" value="{{ $item->name }}" required maxlength="60"
                                   class="flex-1 border rounded px-3 py-2" aria-label="Nom">
                            <span class="text-xs text-gray-500 w-24 text-right">{{ $item->products_count }} produit(s)</span>
                        </div>
                    @endforeach
                    <button class="bg-black text-voom font-semibold rounded px-5 py-2 mt-2">Enregistrer</button>
                </form>
                <div class="flex flex-wrap gap-2 mt-3">
                    @foreach ($group['items'] as $item)
                        <form method="POST" action="{{ route('admin.subcategories.destroy', $item) }}"
                              onsubmit="return confirm('Supprimer « {{ $item->name }} » ? Ses produits resteront en vente sans sous-catégorie.')">
                            @csrf @method('DELETE')
                            <button class="text-xs text-red-700 underline">Supprimer « {{ $item->name }} »</button>
                        </form>
                    @endforeach
                </div>
            @else
                <p class="text-sm text-gray-500">Aucune sous-catégorie.</p>
            @endif

            <form method="POST" action="{{ route('admin.subcategories.store') }}" class="flex gap-2 mt-4 border-t pt-4">
                @csrf
                <input type="hidden" name="category" value="{{ $category }}">
                <input name="name" required maxlength="60" placeholder="Nouvelle sous-catégorie" class="flex-1 border rounded px-3 py-2">
                <button class="border border-black rounded px-4 py-2">Ajouter</button>
            </form>
        </section>
    @endforeach
@endsection
