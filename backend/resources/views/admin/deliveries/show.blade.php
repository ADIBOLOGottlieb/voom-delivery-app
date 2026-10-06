@extends('layouts.admin')

@section('title', $delivery->reference)

@section('content')
    @php
        $maps = fn ($lat, $lng) => "https://www.google.com/maps/search/?api=1&query={$lat},{$lng}";
        $route = "https://www.google.com/maps/dir/?api=1&origin={$delivery->pickup_lat},{$delivery->pickup_lng}&destination={$delivery->dropoff_lat},{$delivery->dropoff_lng}";
        $money = fn ($v) => number_format($v, 0, ',', ' ').' FCFA';
    @endphp

    <div class="flex flex-wrap items-center gap-3 mb-6">
        <a href="{{ route('admin.deliveries.index') }}" class="text-gray-500">← Livraisons</a>
        <h1 class="text-2xl font-bold font-mono">{{ $delivery->reference }}</h1>
        <span class="px-2 py-0.5 rounded-full text-xs {{ $delivery->status->badgeClass() }}">{{ $delivery->status->label() }}</span>
        <span class="px-2 py-0.5 rounded-full text-xs {{ $delivery->payment_status->badgeClass() }}">{{ $delivery->payment_status->label() }}</span>
        <span class="text-gray-500 text-sm">{{ $delivery->type->label() }} · créée le {{ $delivery->created_at->format('d/m/Y H:i') }}</span>
    </div>

    <div class="grid lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2 space-y-6">
            {{-- Trajet --}}
            <section class="bg-white rounded-lg shadow-sm p-5">
                <div class="grid md:grid-cols-2 gap-5">
                    <div>
                        <h2 class="font-semibold text-green-700 mb-1">A · Récupération</h2>
                        <p>{{ $delivery->pickup_address }}</p>
                        <p class="text-sm text-gray-600">{{ $delivery->pickup_contact_name ?? $delivery->client->name }} · {{ $delivery->pickup_contact_phone ?? $delivery->client->phone_number }}</p>
                        <a href="{{ $maps($delivery->pickup_lat, $delivery->pickup_lng) }}" target="_blank" class="text-sm text-blue-600 underline">Voir sur Google Maps</a>
                    </div>
                    <div>
                        <h2 class="font-semibold text-red-700 mb-1">B · Destination</h2>
                        <p>{{ $delivery->dropoff_address }}</p>
                        <p class="text-sm text-gray-600">{{ $delivery->recipient_name }} · {{ $delivery->recipient_phone }}</p>
                        <a href="{{ $maps($delivery->dropoff_lat, $delivery->dropoff_lng) }}" target="_blank" class="text-sm text-blue-600 underline">Voir sur Google Maps</a>
                    </div>
                </div>
                <iframe class="w-full h-72 mt-4 rounded border" loading="lazy"
                        src="https://www.google.com/maps?saddr={{ $delivery->pickup_lat }},{{ $delivery->pickup_lng }}&daddr={{ $delivery->dropoff_lat }},{{ $delivery->dropoff_lng }}&output=embed"></iframe>
                <a href="{{ $route }}" target="_blank" class="inline-block mt-2 text-sm text-blue-600 underline">Ouvrir l'itinéraire A → B</a>
            </section>

            {{-- Détails --}}
            <section class="bg-white rounded-lg shadow-sm p-5">
                <h2 class="font-semibold mb-3">Détails</h2>
                <dl class="grid grid-cols-2 gap-x-6 gap-y-2 text-sm">
                    <dt class="text-gray-500">Client</dt><dd>{{ $delivery->client->name }} · {{ $delivery->client->phone_number }}</dd>
                    @if ($delivery->product)
                        <dt class="text-gray-500">Produit</dt><dd>{{ $delivery->quantity }} × {{ $delivery->product->name }}</dd>
                    @endif
                    <dt class="text-gray-500">Description</dt><dd>{{ $delivery->package_description ?: '—' }}</dd>
                    <dt class="text-gray-500">Notes</dt><dd>{{ $delivery->notes ?: '—' }}</dd>
                    @if ($delivery->scheduled_at)
                        <dt class="text-gray-500">Programmée pour</dt><dd>{{ $delivery->scheduled_at->format('d/m/Y H:i') }}</dd>
                    @endif
                    <dt class="text-gray-500">Distance estimée</dt><dd>{{ $delivery->distance_km }} km</dd>
                    <dt class="text-gray-500">Frais de livraison</dt><dd>{{ $money($delivery->delivery_fee) }}</dd>
                    @if ($delivery->items_amount)
                        <dt class="text-gray-500">Articles</dt><dd>{{ $money($delivery->items_amount) }}</dd>
                    @endif
                    <dt class="text-gray-500 font-semibold">Total</dt><dd class="font-semibold">{{ $money($delivery->total_amount) }}</dd>
                    @if ($delivery->cancel_reason)
                        <dt class="text-gray-500">Motif d'annulation</dt><dd>{{ $delivery->cancel_reason }}</dd>
                    @endif
                </dl>
            </section>

            {{-- Paiements --}}
            <section class="bg-white rounded-lg shadow-sm p-5">
                <h2 class="font-semibold mb-3">Preuves de paiement</h2>
                @forelse ($delivery->payments as $payment)
                    <div class="border rounded-lg p-4 mb-4 grid md:grid-cols-3 gap-4">
                        <a href="{{ route('admin.payments.screenshot', $payment) }}" target="_blank">
                            <img src="{{ route('admin.payments.screenshot', $payment) }}" alt="Capture de la transaction"
                                 class="w-full max-h-80 object-contain bg-gray-50 rounded border">
                        </a>
                        <div class="md:col-span-2 text-sm space-y-1">
                            <div><span class="px-2 py-0.5 rounded-full text-xs {{ $payment->status->badgeClass() }}">{{ $payment->status->label() }}</span></div>
                            <div><span class="text-gray-500">Moyen :</span> {{ $payment->method->label() }}</div>
                            <div><span class="text-gray-500">Réf. transaction :</span> <span class="font-mono">{{ $payment->transaction_ref }}</span></div>
                            <div><span class="text-gray-500">N° payeur :</span> {{ $payment->payer_phone }}</div>
                            <div><span class="text-gray-500">Montant attendu :</span> {{ $money($payment->amount) }}</div>
                            <div><span class="text-gray-500">Envoyée le :</span> {{ $payment->created_at->format('d/m/Y H:i') }}</div>
                            @if ($payment->reviewed_at)
                                <div><span class="text-gray-500">Traitée par :</span> {{ $payment->reviewer?->name }} le {{ $payment->reviewed_at->format('d/m/Y H:i') }}</div>
                            @endif
                            @if ($payment->rejection_reason)
                                <div class="text-red-700">Motif du refus : {{ $payment->rejection_reason }}</div>
                            @endif

                            @if ($payment->status === \App\Enums\PaymentStatus::Submitted)
                                <p class="text-xs text-gray-500 pt-2">Vérifiez sur le compte marchand que la transaction existe et que le montant correspond avant de confirmer.</p>
                                <div class="flex flex-wrap gap-2 pt-1">
                                    <form method="POST" action="{{ route('admin.payments.approve', $payment) }}">
                                        @csrf
                                        <button class="bg-green-600 text-white rounded px-4 py-2">Confirmer le paiement</button>
                                    </form>
                                    <form method="POST" action="{{ route('admin.payments.reject', $payment) }}" class="flex gap-2">
                                        @csrf
                                        <input name="rejection_reason" required placeholder="Motif du refus" class="border rounded px-3 py-2">
                                        <button class="bg-red-600 text-white rounded px-4 py-2">Refuser</button>
                                    </form>
                                </div>
                            @endif
                        </div>
                    </div>
                @empty
                    <p class="text-sm text-gray-500">Le client n'a pas encore envoyé de preuve de paiement.</p>
                @endforelse
            </section>
        </div>

        <aside class="space-y-6">
            {{-- Assignation --}}
            <section class="bg-white rounded-lg shadow-sm p-5">
                <h2 class="font-semibold mb-3">Livreur</h2>
                @if ($delivery->courier)
                    <p class="mb-3">{{ $delivery->courier->name }}<br>
                        <span class="text-sm text-gray-500">{{ $delivery->courier->phone_number }} · {{ $delivery->courier->vehicle ?? 'Véhicule non renseigné' }}</span></p>
                @endif

                @if ($delivery->canBeAssigned())
                    <form method="POST" action="{{ route('admin.deliveries.assign', $delivery) }}" class="space-y-2">
                        @csrf
                        <select name="courier_id" required class="w-full border rounded px-3 py-2">
                            <option value="">Choisir un livreur…</option>
                            @foreach ($couriers as $courier)
                                <option value="{{ $courier->id }}" @selected($delivery->courier_id === $courier->id)>
                                    {{ $courier->name }} ({{ $courier->active_count }} en cours)
                                </option>
                            @endforeach
                        </select>
                        <button class="w-full bg-black text-voom font-semibold rounded py-2">
                            {{ $delivery->courier ? 'Réassigner' : 'Assigner' }}
                        </button>
                    </form>
                @elseif ($delivery->payment_status !== \App\Enums\PaymentStatus::Verified && ! $delivery->status->isFinal())
                    <p class="text-sm text-gray-500">Confirmez d'abord le paiement pour pouvoir assigner un livreur.</p>
                @endif
            </section>

            {{-- Historique --}}
            <section class="bg-white rounded-lg shadow-sm p-5 text-sm">
                <h2 class="font-semibold mb-3">Historique</h2>
                <ul class="space-y-1">
                    <li>Créée : {{ $delivery->created_at->format('d/m/Y H:i') }}</li>
                    @if ($delivery->assigned_at)<li>Assignée : {{ $delivery->assigned_at->format('d/m/Y H:i') }}</li>@endif
                    @if ($delivery->picked_up_at)<li>Récupérée : {{ $delivery->picked_up_at->format('d/m/Y H:i') }}</li>@endif
                    @if ($delivery->delivered_at)<li>Livrée : {{ $delivery->delivered_at->format('d/m/Y H:i') }}</li>@endif
                    @if ($delivery->cancelled_at)<li>Annulée : {{ $delivery->cancelled_at->format('d/m/Y H:i') }}</li>@endif
                </ul>
            </section>

            @unless ($delivery->status->isFinal())
                <section class="bg-white rounded-lg shadow-sm p-5">
                    <h2 class="font-semibold mb-3 text-red-700">Annuler la livraison</h2>
                    <form method="POST" action="{{ route('admin.deliveries.cancel', $delivery) }}" class="space-y-2"
                          onsubmit="return confirm('Annuler définitivement cette livraison ?')">
                        @csrf
                        <input name="reason" required placeholder="Motif" class="w-full border rounded px-3 py-2">
                        <button class="w-full border border-red-600 text-red-700 rounded py-2">Annuler</button>
                    </form>
                </section>
            @endunless
        </aside>
    </div>
@endsection
