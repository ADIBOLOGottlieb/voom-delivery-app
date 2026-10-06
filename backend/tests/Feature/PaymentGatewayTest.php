<?php

namespace Tests\Feature;

use App\Models\Delivery;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request as HttpRequest;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PaymentGatewayTest extends TestCase
{
    use RefreshDatabase;

    private User $client;

    protected function setUp(): void
    {
        parent::setUp();
        $this->client = User::factory()->create();
        Sanctum::actingAs($this->client);
    }

    private function delivery(): Delivery
    {
        $id = $this->postJson('/api/v1/deliveries', [
            'type' => 'colis',
            'pickup_address' => 'Bè', 'pickup_lat' => 6.1375, 'pickup_lng' => 1.24,
            'dropoff_address' => 'Kégué', 'dropoff_lat' => 6.165, 'dropoff_lng' => 1.26,
            'recipient_name' => 'Yao', 'recipient_phone' => '+22893000000',
        ])->assertCreated()->json('data.id');

        return Delivery::findOrFail($id);
    }

    private function usePaygate(): void
    {
        config(['payments.gateway' => 'paygate', 'payments.paygate.auth_token' => 'pg-token']);
    }

    private function useKkiapay(?string $webhookSecret = null): void
    {
        config([
            'payments.gateway' => 'kkiapay',
            'payments.kkiapay.public_key' => 'pub', 'payments.kkiapay.private_key' => 'priv',
            'payments.kkiapay.secret' => 'sec', 'payments.kkiapay.sandbox' => true,
            'payments.kkiapay.webhook_secret' => $webhookSecret,
        ]);
    }

    public function test_manual_mode_without_gateway_keys(): void
    {
        config(['payments.gateway' => 'kkiapay']); // demandé mais sans clés

        $this->getJson('/api/v1/payment-info')->assertOk()->assertJsonPath('mode', 'manual');

        $d = $this->delivery();
        $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'flooz', 'phone' => '90112233'])
            ->assertUnprocessable()->assertJsonValidationErrors('payment');
    }

    public function test_paygate_push_payment_is_confirmed_by_status_polling(): void
    {
        $this->usePaygate();
        Http::fake([
            'paygateglobal.com/api/v1/pay' => Http::response(['tx_reference' => 'TX-1', 'status' => 0]),
            'paygateglobal.com/api/v2/status' => Http::sequence()
                ->push(['status' => 2])
                ->push(['status' => 0, 'tx_reference' => 'TX-1']),
        ]);

        $info = $this->getJson('/api/v1/payment-info')->assertOk();
        $info->assertJsonPath('mode', 'gateway')->assertJsonPath('gateway', 'paygate')->assertJsonCount(2, 'methods');

        $d = $this->delivery();
        $res = $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'mixx', 'phone' => '+228 90 11 22 33'])
            ->assertCreated()
            ->assertJsonPath('mode', 'ussd')
            ->assertJsonPath('payment.status', 'pending');

        Http::assertSent(fn (HttpRequest $r) => str_ends_with($r->url(), '/api/v1/pay')
            && $r['network'] === 'TMONEY'
            && $r['phone_number'] === '90112233'
            && $r['amount'] === $d->total_amount
            && $r['auth_token'] === 'pg-token');

        $paymentId = $res->json('payment.id');
        $this->getJson("/api/v1/deliveries/{$d->id}/payments/{$paymentId}")
            ->assertOk()->assertJsonPath('payment.status', 'pending');
        $this->getJson("/api/v1/deliveries/{$d->id}/payments/{$paymentId}")
            ->assertOk()
            ->assertJsonPath('payment.status', 'verified')
            ->assertJsonPath('delivery.payment_status', 'verified');
    }

    public function test_paygate_refusal_marks_attempt_failed(): void
    {
        $this->usePaygate();
        Http::fake(['paygateglobal.com/*' => Http::response(['status' => 4])]);

        $d = $this->delivery();
        $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'flooz', 'phone' => '99000000'])
            ->assertUnprocessable()->assertJsonValidationErrors('payment');

        $this->assertSame('failed', Payment::firstOrFail()->status->value);
        $this->assertSame('unpaid', $d->refresh()->payment_status->value);
    }

    public function test_paygate_webhook_triggers_server_side_verification(): void
    {
        $this->usePaygate();
        Http::fake([
            'paygateglobal.com/api/v1/pay' => Http::response(['tx_reference' => 'TX-9', 'status' => 0]),
            'paygateglobal.com/api/v2/status' => Http::response(['status' => 0]),
        ]);

        $d = $this->delivery();
        $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'flooz', 'phone' => '99000000'])->assertCreated();
        $token = Payment::firstOrFail()->checkout_token;

        $this->postJson('/api/v1/webhooks/paygate', ['identifier' => $token, 'tx_reference' => 'TX-9'])->assertOk();

        $this->assertSame('verified', $d->refresh()->payment_status->value);
    }

    public function test_kkiapay_widget_return_verifies_transaction(): void
    {
        $this->useKkiapay();
        $d = $this->delivery();
        Http::fake(['api-sandbox.kkiapay.me/*' => Http::response(['status' => 'SUCCESS', 'amount' => $d->total_amount])]);

        $res = $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'flooz', 'phone' => '99000000'])
            ->assertCreated()->assertJsonPath('mode', 'redirect');
        $payment = Payment::firstOrFail();
        $this->assertStringEndsWith("/paiement/{$payment->checkout_token}", $res->json('redirect_url'));

        $this->get("/paiement/{$payment->checkout_token}")->assertOk()->assertSee('cdn.kkiapay.me/k.js', false);
        $this->get("/paiement/{$payment->checkout_token}/retour?transaction_id=KK-1")->assertOk()->assertSee('Paiement confirmé');

        Http::assertSent(fn (HttpRequest $r) => $r['transactionId'] === 'KK-1'
            && $r->hasHeader('X-PRIVATE-KEY', 'priv'));
        $this->assertSame('verified', $d->refresh()->payment_status->value);
    }

    public function test_kkiapay_rejects_underpaid_transaction(): void
    {
        $this->useKkiapay();
        Http::fake(['api-sandbox.kkiapay.me/*' => Http::response(['status' => 'SUCCESS', 'amount' => 100])]);

        $d = $this->delivery();
        $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'mixx', 'phone' => '90000000'])->assertCreated();
        $token = Payment::firstOrFail()->checkout_token;

        $this->get("/paiement/{$token}/retour?transaction_id=KK-LOW")->assertOk()->assertSee('non abouti');
        $this->assertSame('unpaid', $d->refresh()->payment_status->value);
    }

    public function test_kkiapay_webhook_requires_secret_and_matches_by_token(): void
    {
        $this->useKkiapay('hook-secret');
        $d = $this->delivery();
        Http::fake(['api-sandbox.kkiapay.me/*' => Http::response(['status' => 'SUCCESS', 'amount' => $d->total_amount])]);

        $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'flooz', 'phone' => '99000000'])->assertCreated();
        $token = Payment::firstOrFail()->checkout_token;
        $body = ['transactionId' => 'KK-2', 'isPaymentSucces' => true, 'event' => 'transaction.success', 'stateData' => ['data' => $token]];

        $this->postJson('/api/v1/webhooks/kkiapay', $body, ['x-kkiapay-secret' => 'wrong'])->assertUnauthorized();
        $this->assertSame('unpaid', $d->refresh()->payment_status->value);

        $this->postJson('/api/v1/webhooks/kkiapay', $body, ['x-kkiapay-secret' => 'hook-secret'])->assertOk();
        $this->assertSame('verified', $d->refresh()->payment_status->value);
    }

    public function test_a_transaction_cannot_pay_two_deliveries(): void
    {
        $this->useKkiapay();
        Http::fake(['api-sandbox.kkiapay.me/*' => Http::response(['status' => 'SUCCESS', 'amount' => 999999])]);

        $first = $this->delivery();
        $second = $this->delivery();
        foreach ([$first, $second] as $d) {
            $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'flooz', 'phone' => '99000000'])->assertCreated();
        }
        [$p1, $p2] = Payment::orderBy('id')->get()->all();

        $this->get("/paiement/{$p1->checkout_token}/retour?transaction_id=KK-SAME");
        $this->get("/paiement/{$p2->checkout_token}/retour?transaction_id=KK-SAME");

        $this->assertSame('verified', $first->refresh()->payment_status->value);
        $this->assertSame('unpaid', $second->refresh()->payment_status->value);
    }

    public function test_recent_pending_attempt_blocks_a_second_charge(): void
    {
        $this->usePaygate();
        Http::fake([
            'paygateglobal.com/api/v1/pay' => Http::response(['tx_reference' => 'TX-1', 'status' => 0]),
            'paygateglobal.com/api/v2/status' => Http::response(['status' => 2]),
        ]);

        $d = $this->delivery();
        $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'flooz', 'phone' => '99000000'])->assertCreated();
        $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'flooz', 'phone' => '99000000'])
            ->assertUnprocessable()->assertJsonValidationErrors('payment');

        $this->assertSame(1, Payment::count());
    }

    public function test_other_clients_cannot_poll_a_payment(): void
    {
        $this->usePaygate();
        Http::fake(['paygateglobal.com/*' => Http::response(['tx_reference' => 'TX-1', 'status' => 0])]);

        $d = $this->delivery();
        $id = $this->postJson("/api/v1/deliveries/{$d->id}/checkout", ['method' => 'flooz', 'phone' => '99000000'])->json('payment.id');

        Sanctum::actingAs(User::factory()->create());
        $this->getJson("/api/v1/deliveries/{$d->id}/payments/{$id}")->assertNotFound();
    }
}
