<?php

namespace App\Http\Controllers;

use App\Enums\PaymentStatus;
use App\Models\Payment;
use App\Services\Payments\KkiapayGateway;
use App\Services\Payments\PaymentService;
use Illuminate\Http\Request;
use Illuminate\View\View;

/** Page de paiement KKiaPay ouverte depuis l'app (lien à usage unique via le jeton du paiement). */
class CheckoutPageController extends Controller
{
    public function __construct(private readonly PaymentService $payments) {}

    public function show(string $token, KkiapayGateway $kkiapay): View
    {
        $payment = Payment::where('checkout_token', $token)->where('gateway', 'kkiapay')->firstOrFail();

        return view('pay.checkout', [
            'payment' => $payment->load('delivery'),
            'publicKey' => $kkiapay->publicKey(),
            'sandbox' => $kkiapay->isSandbox(),
            'phone' => preg_replace('/\D/', '', (string) $payment->payer_phone),
            'feeLabel' => config('payments.kkiapay.fee_label'),
        ]);
    }

    /** Retour du widget après paiement : rattache la transaction puis la vérifie côté serveur. */
    public function return(Request $request, string $token): View
    {
        $payment = Payment::where('checkout_token', $token)->where('gateway', 'kkiapay')->firstOrFail();

        $transactionId = (string) $request->query('transaction_id', '');
        if ($transactionId !== '') {
            $this->payments->attachReference($payment, $transactionId);
        }
        $payment = $this->payments->refresh($payment->refresh());

        return view('pay.checkout', [
            'payment' => $payment->load('delivery'),
            'result' => $payment->status === PaymentStatus::Verified ? 'success'
                : ($payment->status === PaymentStatus::Pending ? 'pending' : 'failed'),
        ]);
    }
}
