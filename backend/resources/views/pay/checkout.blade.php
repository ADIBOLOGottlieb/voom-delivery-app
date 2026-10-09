<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Paiement · VOOM Delivery</title>
    <link rel="icon" type="image/png" href="{{ asset('images/voom-icon.png') }}">
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 min-h-screen flex flex-col items-center px-4 py-8">
    <img src="{{ asset('images/voom-logo.png') }}" alt="VOOM Delivery" class="w-56 mb-6">

    <div class="bg-white rounded-2xl shadow w-full max-w-sm p-6 text-center">
        <p class="text-gray-500 text-sm">Livraison {{ $payment->delivery->reference }}</p>
        <p class="text-3xl font-bold my-2">{{ number_format($payment->amount, 0, ',', ' ') }} FCFA</p>

        @isset($result)
            @if ($result === 'success')
                <p class="text-green-700 font-semibold text-lg mt-4">✅ Paiement confirmé</p>
                <p class="text-gray-600 mt-2">Vous pouvez retourner dans l'application VOOM Delivery.</p>
            @elseif ($result === 'pending')
                <p class="text-orange-700 font-semibold text-lg mt-4">⏳ Paiement en cours de vérification</p>
                <p class="text-gray-600 mt-2">Retournez dans l'application : la confirmation s'affichera automatiquement.</p>
            @else
                <p class="text-red-700 font-semibold text-lg mt-4">Paiement non abouti</p>
                <p class="text-gray-600 mt-2">Aucun montant n'a été validé. Retournez dans l'application pour réessayer.</p>
            @endif
        @else
            @if ($payment->status->value !== 'pending')
                <p class="text-gray-700 mt-4">Ce lien de paiement n'est plus valide. Retournez dans l'application.</p>
            @elseif ($simulation)
                <p class="mt-4 rounded bg-orange-100 text-orange-800 text-sm p-3 font-semibold">
                    MODE SIMULATION — aucun argent n'est débité.
                </p>
                <form method="POST" action="{{ route('checkout.simulate', $payment->checkout_token) }}" class="mt-6 space-y-3">
                    @csrf
                    <button name="result" value="success" class="w-full bg-yellow-400 hover:bg-yellow-500 text-black font-semibold rounded-lg py-3">
                        Simuler un paiement réussi
                    </button>
                    <button name="result" value="fail" class="w-full border border-red-500 text-red-700 rounded-lg py-3">
                        Simuler un échec
                    </button>
                </form>
            @else
                <p class="text-gray-600 text-sm">Flooz ou Mixx by Yas · {{ $feeLabel }}</p>
                <button id="pay" class="mt-6 w-full bg-yellow-400 hover:bg-yellow-500 text-black font-semibold rounded-lg py-3">
                    Payer maintenant
                </button>
                <p class="text-xs text-gray-400 mt-4">Paiement sécurisé par KKiaPay</p>
            @endif
        @endisset
    </div>

    @if (! isset($result) && empty($simulation) && $payment->status->value === 'pending')
        <script src="https://cdn.kkiapay.me/k.js"></script>
        <script>
            const returnUrl = @json(route('checkout.return', $payment->checkout_token));
            function pay() {
                openKkiapayWidget({
                    amount: @json($payment->amount),
                    key: @json($publicKey),
                    sandbox: @json($sandbox),
                    phone: @json($phone),
                    data: @json($payment->checkout_token),
                    paymentmethod: 'momo',
                    countries: ['TG'],
                    theme: '#FFD700',
                    position: 'center',
                });
            }
            addSuccessListener(response => {
                window.location.href = returnUrl + '?transaction_id=' + encodeURIComponent(response.transactionId);
            });
            document.getElementById('pay').addEventListener('click', pay);
            window.addEventListener('load', pay);
        </script>
    @endif
</body>
</html>
