@extends('layouts.admin')

@section('title', 'Marketplace')

@section('content')
    <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
        <h1 class="text-2xl font-bold">Marketplace</h1>
        <div class="flex flex-wrap gap-2 text-sm">
            <a href="{{ route('admin.products.index') }}" class="px-3 py-1.5 rounded {{ ! $category && ! $type ? 'bg-black text-voom' : 'bg-white' }}">Tous</a>
            @foreach (\App\Models\Product::CATEGORIES as $key => $label)
                <a href="{{ route('admin.products.index', ['category' => $key]) }}" class="px-3 py-1.5 rounded {{ $category === $key ? 'bg-black text-voom' : 'bg-white' }}">{{ $label }}</a>
            @endforeach
            <a href="{{ route('admin.products.index', ['type' => 'pack']) }}" class="px-3 py-1.5 rounded {{ $type === 'pack' ? 'bg-black text-voom' : 'bg-white' }}">Packs</a>
            <a href="{{ route('admin.subcategories.index') }}" class="px-3 py-1.5 rounded bg-white underline">Sous-catégories</a>
        </div>
        <div class="flex gap-2">
            <a href="{{ route('admin.products.create', ['type' => 'pack']) }}" class="border border-black font-semibold rounded px-4 py-2">+ Nouveau pack</a>
            <a href="{{ route('admin.products.create') }}" class="bg-black text-voom font-semibold rounded px-4 py-2">+ Nouveau produit</a>
        </div>
    </div>

    <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
        @forelse ($products as $product)
            <div class="bg-white rounded-lg shadow-sm overflow-hidden {{ $product->is_active ? '' : 'opacity-60' }}">
                @if ($product->imageUrl())
                    <img src="{{ $product->imageUrl() }}" alt="" class="w-full h-40 object-cover">
                @else
                    <div class="w-full h-40 bg-gray-100 flex items-center justify-center text-4xl">📦</div>
                @endif
                <div class="p-4">
                    <div class="text-xs text-gray-500">
                        {{ \App\Models\Product::CATEGORIES[$product->category] ?? $product->category }}{{ $product->subcategory ? ' › '.$product->subcategory->name : '' }}
                        · {{ $product->vendor_name ?? 'VOOM' }}
                    </div>
                    <div class="font-semibold">
                        @if ($product->isPack())<span class="text-xs bg-black text-voom rounded px-1.5 py-0.5 mr-1">PACK</span>@endif
                        {{ $product->name }}
                    </div>
                    <div class="text-sm">{{ number_format($product->price, 0, ',', ' ') }} F {{ $product->unit ? '/ '.$product->unit : '' }}</div>
                    @unless ($product->is_active)<div class="text-xs text-red-700">Masqué</div>@endunless
                    <div class="flex gap-3 mt-3 text-sm">
                        <a href="{{ route('admin.products.edit', $product) }}" class="text-blue-600 underline">Modifier</a>
                        <form method="POST" action="{{ route('admin.products.destroy', $product) }}" onsubmit="return confirm('Supprimer ce produit ?')">
                            @csrf @method('DELETE')
                            <button class="text-red-700 underline">Supprimer</button>
                        </form>
                    </div>
                </div>
            </div>
        @empty
            <p class="text-gray-500">Aucun produit.</p>
        @endforelse
    </div>
    <div class="mt-4">{{ $products->links() }}</div>
@endsection
