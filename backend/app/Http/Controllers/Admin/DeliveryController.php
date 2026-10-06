<?php

namespace App\Http\Controllers\Admin;

use App\Enums\DeliveryStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\Payment;
use App\Models\User;
use App\Services\Payments\PaymentService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

class DeliveryController extends Controller
{
    public function dashboard(): View
    {
        return view('admin.dashboard', [
            'paymentsToReview' => Delivery::where('payment_status', PaymentStatus::Submitted)->count(),
            'toAssign' => Delivery::where('status', DeliveryStatus::Pending)
                ->where('payment_status', PaymentStatus::Verified)->count(),
            'inProgress' => Delivery::whereIn('status', [DeliveryStatus::Assigned, DeliveryStatus::PickedUp])->count(),
            'deliveredToday' => Delivery::where('status', DeliveryStatus::Delivered)
                ->whereDate('delivered_at', today())->count(),
            'activeCouriers' => User::couriers()->where('is_active', true)->count(),
            'revenueMonth' => Delivery::where('payment_status', PaymentStatus::Verified)
                ->where('status', '!=', DeliveryStatus::Cancelled)
                ->whereBetween('created_at', [now()->startOfMonth(), now()])
                ->sum('total_amount'),
            'latest' => Delivery::with(['client', 'courier'])->latest()->limit(8)->get(),
        ]);
    }

    public function index(Request $request): View
    {
        $filters = $request->validate([
            'status' => ['nullable', Rule::enum(DeliveryStatus::class)],
            'payment_status' => ['nullable', Rule::enum(PaymentStatus::class)],
            'search' => ['nullable', 'string', 'max:100'],
        ]);

        $deliveries = Delivery::query()
            ->with(['client', 'courier'])
            ->when($filters['status'] ?? null, fn ($q, $s) => $q->where('status', $s))
            ->when($filters['payment_status'] ?? null, fn ($q, $s) => $q->where('payment_status', $s))
            ->when($filters['search'] ?? null, fn ($q, $s) => $q->where(fn ($q) => $q
                ->where('reference', 'like', "%{$s}%")
                ->orWhere('recipient_phone', 'like', "%{$s}%")
                ->orWhereHas('client', fn ($q) => $q->where('name', 'like', "%{$s}%")->orWhere('phone_number', 'like', "%{$s}%"))))
            ->latest()
            ->paginate(25)
            ->withQueryString();

        return view('admin.deliveries.index', compact('deliveries', 'filters'));
    }

    public function show(Delivery $delivery): View
    {
        $delivery->load(['client', 'courier', 'product', 'payments.reviewer']);

        $couriers = User::couriers()
            ->where('is_active', true)
            ->withCount(['assignedDeliveries as active_count' => fn ($q) => $q
                ->whereIn('status', [DeliveryStatus::Assigned, DeliveryStatus::PickedUp])])
            ->orderBy('name')
            ->get();

        return view('admin.deliveries.show', compact('delivery', 'couriers'));
    }

    public function assign(Request $request, Delivery $delivery): RedirectResponse
    {
        $data = $request->validate(['courier_id' => ['required', 'exists:users,id']]);

        $delivery->assignTo(User::findOrFail($data['courier_id']));

        return back()->with('success', 'Livreur assigné.');
    }

    /** Validation du paiement par l'admin (espèces, virement vérifié manuellement, test). */
    public function confirmPayment(Request $request, Delivery $delivery, PaymentService $payments): RedirectResponse
    {
        $data = $request->validate([
            'method' => ['required', Rule::enum(PaymentMethod::class)],
            'reference' => ['nullable', 'string', 'max:100'],
        ]);

        $payments->confirmByAdmin($delivery, $request->user(), PaymentMethod::from($data['method']), $data['reference'] ?? null);

        return back()->with('success', 'Paiement validé. Vous pouvez assigner un livreur.');
    }

    public function cancel(Request $request, Delivery $delivery): RedirectResponse
    {
        $data = $request->validate(['reason' => ['required', 'string', 'max:255']]);

        $delivery->cancel($data['reason']);

        return back()->with('success', 'Livraison annulée.');
    }

    public function approvePayment(Request $request, Payment $payment): RedirectResponse
    {
        abort_unless($payment->status === PaymentStatus::Submitted, 422, 'Ce paiement a déjà été traité.');
        if ($payment->delivery->status === DeliveryStatus::Cancelled) {
            return back()->withErrors(['payment' => 'Livraison annulée : le paiement ne peut pas être confirmé (rembourser le client si nécessaire).']);
        }

        DB::transaction(function () use ($request, $payment) {
            $payment->forceFill([
                'status' => PaymentStatus::Verified,
                'reviewed_by' => $request->user()->id,
                'reviewed_at' => now(),
            ])->save();
            $payment->delivery->forceFill(['payment_status' => PaymentStatus::Verified])->save();
        });

        return back()->with('success', 'Paiement confirmé. Vous pouvez maintenant assigner un livreur.');
    }

    public function rejectPayment(Request $request, Payment $payment): RedirectResponse
    {
        abort_unless($payment->status === PaymentStatus::Submitted, 422, 'Ce paiement a déjà été traité.');

        $data = $request->validate(['rejection_reason' => ['required', 'string', 'max:255']]);

        DB::transaction(function () use ($request, $payment, $data) {
            $payment->forceFill([
                'status' => PaymentStatus::Rejected,
                'reviewed_by' => $request->user()->id,
                'reviewed_at' => now(),
                'rejection_reason' => $data['rejection_reason'],
            ])->save();
            $payment->delivery->forceFill(['payment_status' => PaymentStatus::Rejected])->save();
        });

        return back()->with('success', 'Paiement refusé. Le client peut renvoyer une preuve.');
    }

    /** Capture d'écran stockée sur le disque privé : accessible uniquement aux admins. */
    public function screenshot(Payment $payment): StreamedResponse
    {
        abort_unless(Storage::disk('local')->exists($payment->screenshot_path), 404);

        return Storage::disk('local')->response($payment->screenshot_path);
    }
}
