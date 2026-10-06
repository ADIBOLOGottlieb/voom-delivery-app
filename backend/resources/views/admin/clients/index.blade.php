@extends('layouts.admin')

@section('title', 'Clients')

@section('content')
    <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
        <h1 class="text-2xl font-bold">Clients</h1>
        <form method="GET" class="flex gap-2">
            <input name="search" value="{{ $search }}" placeholder="Nom, téléphone, email" class="border rounded px-3 py-2 w-64">
            <button class="bg-black text-voom rounded px-4 py-2 font-semibold">Rechercher</button>
        </form>
    </div>

    <div class="bg-white rounded-lg shadow-sm overflow-x-auto">
        <table class="min-w-full text-sm">
            <thead class="bg-gray-50 text-left text-gray-500">
            <tr>
                <th class="px-4 py-2">Nom</th>
                <th class="px-4 py-2">Téléphone</th>
                <th class="px-4 py-2">Email</th>
                <th class="px-4 py-2 text-center">Livraisons</th>
                <th class="px-4 py-2">Inscrit le</th>
                <th class="px-4 py-2"></th>
            </tr>
            </thead>
            <tbody class="divide-y">
            @forelse ($clients as $client)
                <tr>
                    <td class="px-4 py-2 font-medium">{{ $client->name }}</td>
                    <td class="px-4 py-2">{{ $client->phone_number }}</td>
                    <td class="px-4 py-2">{{ $client->email ?? '—' }}</td>
                    <td class="px-4 py-2 text-center">
                        <a class="text-blue-600 underline" href="{{ route('admin.deliveries.index', ['search' => $client->phone_number]) }}">{{ $client->deliveries_count }}</a>
                    </td>
                    <td class="px-4 py-2">{{ $client->created_at->format('d/m/Y') }}</td>
                    <td class="px-4 py-2 text-right">
                        <form method="POST" action="{{ route('admin.clients.toggle', $client) }}">
                            @csrf
                            <button class="text-sm {{ $client->is_active ? 'text-red-700' : 'text-green-700' }} underline">
                                {{ $client->is_active ? 'Désactiver' : 'Réactiver' }}
                            </button>
                        </form>
                    </td>
                </tr>
            @empty
                <tr><td colspan="6" class="px-4 py-8 text-center text-gray-500">Aucun client.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>
    <div class="mt-4">{{ $clients->links() }}</div>
@endsection
