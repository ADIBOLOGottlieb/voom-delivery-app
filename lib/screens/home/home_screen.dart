import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import 'delivery_detail_screen.dart';
import 'main_screen.dart';
import 'new_delivery_screen.dart';
import 'plis_colis_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Delivery>> _recent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _recent = context.read<DeliveryService>().myDeliveries();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _recent.catchError((_) => <Delivery>[]);
  }

  Future<void> _newDelivery(DeliveryType type) async {
    final created = await Navigator.of(context).push<Delivery>(
      MaterialPageRoute(builder: (_) => NewDeliveryScreen(initialType: type)),
    );
    if (created != null && mounted) {
      setState(_load);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeliveryDetailScreen(deliveryId: created.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bonjour,', style: textTheme.bodyLarge),
                          Text(
                            user?.name ?? 'Utilisateur',
                            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text("Que souhaitez-vous faire aujourd'hui ?",
                              style: textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary)),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.secondary,
                      child: Text(
                        user?.initial ?? 'U',
                        style: textTheme.headlineSmall?.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Nos Services', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _ServiceCard(
                    icon: Icons.local_shipping,
                    title: 'Plis & Colis',
                    description: "D'un point A à un point B",
                    color: AppColors.info,
                    onTap: () => _newDelivery(DeliveryType.colis),
                  ),
                  _ServiceCard(
                    icon: Icons.flash_on,
                    title: 'Express',
                    description: 'Prise en charge prioritaire',
                    color: AppColors.warning,
                    onTap: () => _newDelivery(DeliveryType.express),
                  ),
                  _ServiceCard(
                    icon: Icons.shopping_bag,
                    title: 'Shopping',
                    description: 'Achetez, on vous livre',
                    color: AppColors.primaryDark,
                    onTap: () => widget.onNavigate(MainScreen.tabShopping),
                  ),
                  _ServiceCard(
                    icon: Icons.agriculture,
                    title: 'Agroalimentaire',
                    description: 'Produits frais locaux',
                    color: AppColors.success,
                    onTap: () => widget.onNavigate(MainScreen.tabAgro),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Livraisons récentes', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => widget.onNavigate(MainScreen.tabDeliveries),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Delivery>>(
                future: _recent,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString(), style: const TextStyle(color: AppColors.error));
                  }
                  final items = snapshot.data!.take(3).toList();
                  if (items.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.inbox_outlined, size: 40, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text('Aucune livraison pour le moment', style: textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final d in items)
                        DeliveryCard(
                          delivery: d,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DeliveryDetailScreen(deliveryId: d.id)),
                            );
                            if (mounted) setState(_load);
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center, maxLines: 1),
              const SizedBox(height: 4),
              Text(description,
                  style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}
