@extends('layouts.admin')
@section('title', 'Dépenses')
@section('content')
<div class="flex justify-between items-center mb-4"><h1 class="text-2xl font-bold">Dépenses</h1><a class="bg-black text-voom rounded px-4 py-2" href="{{ route('admin.expenses.create') }}">+ Ajouter</a></div>
<p class="bg-white p-4 rounded mb-4">Total du mois : <strong>{{ number_format($total, 0, ',', ' ') }} FCFA</strong></p>
<div class="bg-white rounded shadow-sm overflow-x-auto"><table class="w-full text-sm"><thead><tr class="text-left border-b"><th class="p-3">Date</th><th>Motif</th><th>Bénéficiaire</th><th>Montant</th><th></th></tr></thead><tbody>@forelse($expenses as $expense)<tr class="border-b"><td class="p-3">{{ $expense->spent_on->format('d/m/Y') }}</td><td>{{ $expense->reason }}</td><td>{{ $expense->recipient }}</td><td>{{ number_format($expense->amount, 0, ',', ' ') }} F</td><td><a class="underline" href="{{ route('admin.expenses.edit', $expense) }}">Modifier</a><form method="POST" class="inline" action="{{ route('admin.expenses.destroy', $expense) }}">@csrf @method('DELETE')<button class="ml-3 text-red-600" onclick="return confirm('Supprimer cette dépense ?')">Supprimer</button></form></td></tr>@empty<tr><td colspan="5" class="p-6 text-center">Aucune dépense.</td></tr>@endforelse</tbody></table></div>{{ $expenses->links() }}
@endsection
