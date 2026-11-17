@extends('layouts.admin')
@section('title', 'Statistiques livreurs')
@section('content')
<h1 class="text-2xl font-bold mb-4">Courses par livreur</h1><form class="mb-4"><label>Mois <input type="month" name="month" value="{{ $month }}" class="border rounded p-2"></label><button class="bg-black text-voom rounded px-4 py-2">Afficher</button></form><div class="bg-white rounded shadow-sm overflow-x-auto"><table class="w-full"><thead><tr class="text-left border-b"><th class="p-3">Livreur</th><th>Note moyenne</th><th>Courses validées</th><th>Annulées sur ses courses</th><th>Annulées par lui</th></tr></thead><tbody>@foreach($couriers as $c)<tr class="border-b"><td class="p-3">{{ $c->name }}</td><td>{{ $c->courier_reviews_avg_rating ? number_format($c->courier_reviews_avg_rating, 1) .' / 5' : '—' }}</td><td>{{ $c->delivered_count }}</td><td>{{ $c->cancelled_count }}</td><td>{{ $c->cancelled_by_count }}</td></tr>@endforeach</tbody></table></div>
@endsection
