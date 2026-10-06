import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_chip.dart';
import 'delivery_detail_screen.dart';
import 'new_delivery_screen.dart';

/// Onglet « Plis & Colis » : liste des demandes du client et création.
class PlisColisScreen extends StatefulWidget {
  const PlisColisScreen({super.key});

  @override
  State<PlisColisScreen> createState() => _PlisColisScreenState();
}

class _PlisColisScreenState extends State<PlisColisScreen> {
  late Future<List<Delivery>> _deliveries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _deliveries = context.read<DeliveryService>().myDeliveries();

  Future<void> _refresh() async {
    setState(_load);
    await _deliveries.catchError((_) => <Delivery>[]);
  }

  Future<void> _create([DeliveryType type = DeliveryType.colis]) async {
    final created = await Navigator.of(context).push<Delivery>(
      MaterialPageRoute(builder: (_) => NewDeliveryScreen(initialType: type)),
    );
    if (created != null && mounted) {
      setState(_load);
      await _open(created);
    }
  }

  Future<void> _open(Delivery d) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeliveryDetailScreen(deliveryId: d.id)));
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plis & Colis'),
        backgroundColor: AppColors.info,
        foregroundColor: AppColors.background,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text('Nouvelle demande', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (type, icon, color) in [
                    (DeliveryType.plis, Icons.mail, AppColors.primaryDark),
                    (DeliveryType.colis, Icons.inventory_2, AppColors.info),
                    (DeliveryType.express, Icons.flash_on, AppColors.warning),
                    (DeliveryType.programmee, Icons.schedule, AppColors.success),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => _create(type),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 92,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: color, size: 30),
                              const SizedBox(height: 6),
                              Text(type.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Mes livraisons', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<List<Delivery>>(
              future: _deliveries,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorRetry(message: snapshot.error.toString(), onRetry: () => setState(_load));
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Aucune livraison. Appuyez sur « Nouvelle livraison » pour commencer.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(children: [for (final d in items) DeliveryCard(delivery: d, onTap: () => _open(d))]);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-delivery',
        onPressed: _create,
        backgroundColor: AppColors.info,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle livraison'),
      ),
    );
  }
}

/// Carte résumant une livraison (utilisée par le client).
class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onTap;

  const DeliveryCard({super.key, required this.delivery, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(d.reference, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('· ${d.type.label}', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  StatusChip.delivery(d),
                ],
              ),
              const SizedBox(height: 10),
              _PointLine(label: 'A', color: AppColors.success, text: d.pickup.address),
              const SizedBox(height: 4),
              _PointLine(label: 'B', color: AppColors.error, text: d.dropoff.address),
              const SizedBox(height: 10),
              Row(
                children: [
                  StatusChip.payment(d),
                  const Spacer(),
                  Text(formatFcfa(d.totalAmount), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointLine extends StatelessWidget {
  final String label;
  final Color color;
  final String text;

  const _PointLine({required this.label, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: color,
          child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
