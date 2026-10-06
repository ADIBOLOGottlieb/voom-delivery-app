import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery.dart';
import '../../services/api_client.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import '../../utils/formatters.dart';
import '../../utils/launchers.dart';
import '../../widgets/delivery_map.dart';
import '../../widgets/status_chip.dart';
import 'payment_screen.dart';

/// Suivi d'une livraison par le client.
class DeliveryDetailScreen extends StatefulWidget {
  final int deliveryId;

  const DeliveryDetailScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  Delivery? _delivery;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await context.read<DeliveryService>().getDelivery(widget.deliveryId);
      if (mounted) {
        setState(() {
          _delivery = d;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _pay() async {
    final updated = await Navigator.of(context).push<Delivery>(
      MaterialPageRoute(builder: (_) => PaymentScreen(delivery: _delivery!)),
    );
    if (updated != null && mounted) setState(() => _delivery = updated);
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui, annuler')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final d = await context.read<DeliveryService>().cancelDelivery(_delivery!.id);
      if (mounted) setState(() => _delivery = d);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _delivery;
    return Scaffold(
      appBar: AppBar(title: Text(d?.reference ?? 'Livraison')),
      body: d == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.error)),
                        TextButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    StatusChip.delivery(d),
                    StatusChip.payment(d),
                    StatusChip(label: d.type.label, color: AppColors.secondary),
                  ]),
                  const SizedBox(height: 16),
                  _PaymentBanner(delivery: d, onPay: _pay),
                  const SizedBox(height: 16),
                  DeliveryMap(pickup: d.pickup, dropoff: d.dropoff, height: 220),
                  const SizedBox(height: 16),
                  _PointTile(letter: 'A', color: AppColors.success, title: 'Récupération', point: d.pickup),
                  _PointTile(letter: 'B', color: AppColors.error, title: 'Destination', point: d.dropoff),
                  if (d.courier != null)
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.secondary,
                          child: Icon(Icons.delivery_dining, color: AppColors.primary),
                        ),
                        title: Text('Livreur : ${d.courier!.name}'),
                        subtitle: Text(d.courier!.vehicle ?? ''),
                        trailing: d.courier!.phoneNumber == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.call, color: AppColors.success),
                                onPressed: () => callPhone(context, d.courier!.phoneNumber!),
                              ),
                      ),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (d.packageDescription != null) _Row('Contenu', d.packageDescription!),
                          if (d.scheduledAt != null) _Row('Programmée', formatDateTime(d.scheduledAt!)),
                          _Row('Distance estimée', formatKm(d.distanceKm)),
                          _Row('Frais de livraison', formatFcfa(d.deliveryFee)),
                          if (d.itemsAmount > 0) _Row('Articles', formatFcfa(d.itemsAmount)),
                          const Divider(),
                          _Row('Total', formatFcfa(d.totalAmount), bold: true),
                          _Row('Créée le', formatDateTime(d.createdAt)),
                          if (d.deliveredAt != null) _Row('Livrée le', formatDateTime(d.deliveredAt!)),
                          if (d.cancelReason != null) _Row('Annulation', d.cancelReason!),
                        ],
                      ),
                    ),
                  ),
                  if (d.canCancel) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _busy ? null : _cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Annuler la demande'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _PaymentBanner extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onPay;

  const _PaymentBanner({required this.delivery, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    final (Color color, String text) = switch (d.paymentStatus) {
      PaymentStatus.submitted => (AppColors.warning, "Preuve de paiement reçue. L'agence vérifie la transaction."),
      PaymentStatus.verified => (AppColors.success, 'Paiement confirmé. Un livreur va être assigné.'),
      PaymentStatus.rejected => (
          AppColors.error,
          'Paiement refusé${d.latestPayment?.rejectionReason != null ? ' : ${d.latestPayment!.rejectionReason}' : ''}. Renvoyez une preuve valide.'
        ),
      _ => (AppColors.info, 'Payez ${formatFcfa(d.totalAmount)} par Flooz ou Mixx by Yas pour confirmer la demande.'),
    };
    if (d.status == DeliveryStatus.cancelled) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text),
          if (d.canPay) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Payer et envoyer la capture'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointTile extends StatelessWidget {
  final String letter;
  final Color color;
  final String title;
  final DeliveryPoint point;

  const _PointTile({required this.letter, required this.color, required this.title, required this.point});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([point.address, point.contactName, point.contactPhone].whereType<String>().join('\n')),
        isThreeLine: true,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
