@extends('layouts.admin')

@section('title', 'Annonces promo')

@section('content')
    <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
        <h1 class="text-2xl font-bold">Annonces promo</h1>
        <a href="{{ route('admin.promotions.create') }}" class="bg-black text-voom font-semibold rounded px-4 py-2">+ Nouvelle annonce</a>
    </div>

    @unless ($pushReady)
        <div class="mb-4 rounded border border-orange-300 bg-orange-50 px-4 py-3 text-sm text-orange-800">
            Les annonces s'affichent dans l'app. Pour les envoyer aussi en notification push, configurez Firebase
            (variable <code>FIREBASE_CREDENTIALS</code>, voir le README).
        </div>
    @endunless

    <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
        @forelse ($promotions as $promo)
            <div class="bg-white rounded-lg shadow-sm overflow-hidden {{ $promo->isVisible() ? '' : 'opacity-60' }}">
                @if ($promo->imageUrl())
                    <img src="{{ $promo->imageUrl() }}" alt="" class="w-full h-36 object-cover">
                @else
                    <div class="w-full h-36 bg-gradient-to-br from-yellow-300 to-yellow-500 flex items-center justify-center text-4xl">📣</div>
                @endif
                <div class="p-4 space-y-1">
                    <div class="font-semibold">{{ $promo->title }}</div>
                    <p class="text-sm text-gray-600">{{ $promo->body }}</p>
                    @if ($promo->product)
                        <p class="text-xs text-gray-500">Lien : {{ $promo->product->name }}</p>
                    @endif
                    <p class="text-xs text-gray-500">
                        {{ $promo->starts_at ? 'Du '.$promo->starts_at->format('d/m/Y H:i') : 'Dès maintenant' }}
                        {{ $promo->ends_at ? ' au '.$promo->ends_at->format('d/m/Y H:i') : ', sans fin' }}
                    </p>
                    <p class="text-xs">
                        <span class="px-2 py-0.5 rounded-full {{ $promo->isVisible() ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-700' }}">
                            {{ $promo->isVisible() ? 'Visible dans l\'app' : 'Non visible' }}
                        </span>
                        @if ($promo->pushed_at)
                            <span class="text-gray-500">· notifiée le {{ $promo->pushed_at->format('d/m H:i') }}</span>
                        @endif
                    </p>
                    <div class="flex flex-wrap gap-3 pt-2 text-sm">
                        <a href="{{ route('admin.promotions.edit', $promo) }}" class="text-blue-600 underline">Modifier</a>
                        <form method="POST" action="{{ route('admin.promotions.push', $promo) }}"
                              onsubmit="return confirm('Envoyer cette annonce en notification à tous les clients ?')">
                            @csrf
                            <button class="text-green-700 underline">Envoyer la notification</button>
                        </form>
                        <form method="POST" action="{{ route('admin.promotions.destroy', $promo) }}" onsubmit="return confirm('Supprimer cette annonce ?')">
                            @csrf @method('DELETE')
                            <button class="text-red-700 underline">Supprimer</button>
                        </form>
                    </div>
                </div>
            </div>
        @empty
            <p class="text-gray-500">Aucune annonce. Créez-en une pour l'afficher en bandeau dans l'app.</p>
        @endforelse
    </div>
    <div class="mt-4">{{ $promotions->links() }}</div>
@endsection
