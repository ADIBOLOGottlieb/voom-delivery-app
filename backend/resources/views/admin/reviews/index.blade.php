@extends('layouts.admin')
@section('title', 'Avis clients')
@section('content')
<h1 class="text-2xl font-bold mb-4">Avis sur les livreurs</h1><div class="bg-white rounded shadow-sm overflow-x-auto"><table class="w-full"><thead><tr class="text-left border-b"><th class="p-3">Date</th><th>Livreur</th><th>Client</th><th>Course</th><th>Note</th><th>Avis</th></tr></thead><tbody>@forelse($reviews as $r)<tr class="border-b"><td class="p-3">{{ $r->created_at->format('d/m/Y') }}</td><td>{{ $r->courier?->name }}</td><td>{{ $r->client?->name }}</td><td>{{ $r->delivery?->reference }}</td><td>{{ $r->rating }}/5</td><td>{{ $r->comment }}</td></tr>@empty<tr><td colspan="6" class="p-6 text-center">Aucun avis pour le moment.</td></tr>@endforelse</tbody></table></div>{{ $reviews->links() }}
@endsection
