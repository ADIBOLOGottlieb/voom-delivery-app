import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/voom_logo.dart';
import '../home/profile_screen.dart';
import 'courier_delivery_screen.dart';

/// Espace livreur : livraisons assignées par l'admin.
class CourierHomeScreen extends StatelessWidget {
  const CourierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          leadingWidth: 104,
          leading: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Center(child: VoomLogo(width: 92)),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mes livraisons', style: TextStyle(color: AppColors.primary)),
              Text(user?.name ?? '', style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Profil',
              icon: const Icon(Icons.account_circle),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'À faire'), Tab(text: 'Historique')],
          ),
        ),
        body: const TabBarView(children: [_CourierList(history: false), _CourierList(history: true)]),
      ),
    );
  }
}

class _CourierList extends StatefulWidget {
  final bool history;

  const _CourierList({required this.history});

  @override
  State<_CourierList> createState() => _CourierListState();
}

class _CourierListState extends State<_CourierList> with AutomaticKeepAliveClientMixin {
  late Future<List<Delivery>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = context.read<DeliveryService>().courierDeliveries(history: widget.history);

  Future<void> _refresh() async {
    setState(_load);
    await _future.catchError((_) => <Delivery>[]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Delivery>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  TextButton(onPressed: () => setState(_load), child: const Text('Réessayer')),
                ]),
              ),
            ]);
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(children: [
                  const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    widget.history
                        ? 'Aucune livraison terminée.'
                        : 'Aucune livraison assignée pour le moment.\nTirez pour actualiser.',
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ]);
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
            itemCount: items.length,
            itemBuilder: (context, i) => _CourierCard(
              delivery: items[i],
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CourierDeliveryScreen(deliveryId: items[i].id)),
                );
                if (mounted) setState(_load);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CourierCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onTap;

  const _CourierCard({required this.delivery, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    // Prochaine étape : récupérer en A tant que le colis n'est pas pris, sinon livrer en B.
    final nextIsPickup = d.status == DeliveryStatus.assigned;
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
              Row(children: [
                Text(d.reference, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                if (d.type == DeliveryType.express) const StatusChip(label: 'EXPRESS', color: AppColors.warning),
                const Spacer(),
                StatusChip.delivery(d),
              ]),
              const SizedBox(height: 12),
              _Line(
                icon: Icons.store,
                color: AppColors.success,
                text: d.pickup.address,
                highlight: d.isActive && nextIsPickup,
              ),
              const SizedBox(height: 6),
              _Line(
                icon: Icons.flag,
                color: AppColors.error,
                text: d.dropoff.address,
                highlight: d.isActive && !nextIsPickup,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Text(formatKm(d.distanceKm), style: Theme.of(context).textTheme.bodySmall),
                if (d.scheduledAt != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule, size: 14),
                  const SizedBox(width: 4),
                  Text(formatDateTime(d.scheduledAt!), style: Theme.of(context).textTheme.bodySmall),
                ],
                const Spacer(),
                const Icon(Icons.chevron_right),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool highlight;

  const _Line({required this.icon, required this.color, required this.text, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: highlight ? FontWeight.w700 : FontWeight.normal),
        ),
      ),
    ]);
  }
}
