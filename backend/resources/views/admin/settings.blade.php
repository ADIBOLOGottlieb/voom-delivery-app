@extends('layouts.admin')

@section('title', 'Réglages')

@section('content')
    <h1 class="text-2xl font-bold mb-4">Réglages</h1>

    <form method="POST" action="{{ route('admin.settings.update') }}" class="space-y-6 max-w-2xl">
        @csrf @method('PUT')

        <section class="bg-white rounded-lg shadow-sm p-6 space-y-4">
            <h2 class="font-semibold">Paiement mobile money</h2>

            <div class="rounded border p-4 text-sm {{ $gateway['active'] ? 'bg-green-50 border-green-200' : 'bg-orange-50 border-orange-200' }}">
                @if ($gateway['active'])
                    <p class="font-semibold text-green-800">
                        Paiement en ligne actif : {{ $gateway['active'] === 'kkiapay' ? 'KKiaPay' : 'PayGate Global' }}
                        @if ($gateway['active'] === 'kkiapay' && $gateway['sandbox']) <span class="text-orange-700">(mode test / sandbox)</span> @endif
                    </p>
                    <p class="text-gray-600 mt-1">Les clients paient Flooz ou Mixx by Yas dans l'app ; le paiement est confirmé automatiquement.</p>
                @else
                    <p class="font-semibold text-orange-800">Mode manuel : virement sur les numéros ci-dessous + capture d'écran à vérifier.</p>
                    @if ($gateway['requested'] !== 'manual')
                        <p class="text-gray-600 mt-1">« {{ $gateway['requested'] }} » est demandé mais ses clés sont absentes du fichier .env.</p>
                    @endif
                @endif
                <p class="text-gray-500 mt-2">Agrégateur et clés : variables <code>PAYMENT_GATEWAY</code>, <code>KKIAPAY_*</code> / <code>PAYGATE_AUTH_TOKEN</code> (voir le README).</p>
                <p class="text-gray-500">URL de notification à déclarer : KKiaPay <code class="break-all">{{ $gateway['webhook_kkiapay'] }}</code> · PayGate <code class="break-all">{{ $gateway['webhook_paygate'] }}</code></p>
            </div>

            <p class="text-sm text-gray-500">Numéros marchands (mode manuel) : affichés aux clients uniquement si le paiement en ligne est désactivé.</p>
            <div>
                <label class="block text-sm font-medium mb-1">Nom du compte marchand</label>
                <input name="merchant_name" value="{{ old('merchant_name', $settings['merchant_name']) }}" required class="w-full border rounded px-3 py-2">
            </div>
            <div class="grid grid-cols-2 gap-4">
                <div>
                    <label class="block text-sm font-medium mb-1">Numéro marchand Flooz (Moov Africa)</label>
                    <input name="flooz_merchant_number" value="{{ old('flooz_merchant_number', $settings['flooz_merchant_number']) }}" class="w-full border rounded px-3 py-2">
                </div>
                <div>
                    <label class="block text-sm font-medium mb-1">Numéro marchand Mixx by Yas</label>
                    <input name="mixx_merchant_number" value="{{ old('mixx_merchant_number', $settings['mixx_merchant_number']) }}" class="w-full border rounded px-3 py-2">
                </div>
            </div>
            <div>
                <label class="block text-sm font-medium mb-1">Instructions affichées au client</label>
                <textarea name="payment_instructions" rows="3" class="w-full border rounded px-3 py-2">{{ old('payment_instructions', $settings['payment_instructions']) }}</textarea>
            </div>
        </section>

        <section class="bg-white rounded-lg shadow-sm p-6 space-y-4">
            <h2 class="font-semibold">Tarification (FCFA)</h2>
            <p class="text-sm text-gray-500">Frais = forfait + distance estimée × prix au km (+ supplément Express), avec un minimum, arrondi à 50 F.</p>
            <div class="grid grid-cols-2 gap-4">
                @foreach (['base_fee' => 'Forfait de base', 'per_km_fee' => 'Prix par km', 'express_fee' => 'Supplément Express', 'min_fee' => 'Frais minimum'] as $key => $label)
                    <div>
                        <label class="block text-sm font-medium mb-1">{{ $label }}</label>
                        <input name="{{ $key }}" type="number" min="0" value="{{ old($key, $settings[$key]) }}" required class="w-full border rounded px-3 py-2">
                    </div>
                @endforeach
            </div>
        </section>

        <button class="bg-black text-voom font-semibold rounded px-6 py-2">Enregistrer</button>
    </form>
@endsection
