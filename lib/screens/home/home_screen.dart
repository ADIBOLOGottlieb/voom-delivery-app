import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import '../../widgets/promo_carousel.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/user_avatar.dart';
import 'delivery_detail_screen.dart';
import 'main_screen.dart';
import 'new_delivery_screen.dart';
import 'plis_colis_screen.dart';
import 'product_catalog_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final VoidCallback onStartDelivery;

  const HomeScreen({super.key, required this.onNavigate, required this.onStartDelivery});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Future<List<Delivery>> _recent;
  late Future<List<Promotion>> _promos;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _recent = context.read<DeliveryService>().myDeliveries();
    _promos = context.read<DeliveryService>().promotions().catchError((_) => <Promotion>[]);
  }

  void reload() => setState(_load);

  Future<void> _refresh() async {
    final auth = context.read<AuthService>();
    setState(_load);
    // Le statut « client habitué » peut avoir été accordé par l'agence entre-temps.
    await Future.wait([_recent.catchError((_) => <Delivery>[]), auth.refreshProfile()]);
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              // En-tête : salutation + photo de profil (touchée = onglet Profil).
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour ${user?.firstName ?? ''} 👋', style: textTheme.bodyLarge),
                        Text(
                          'Que livrons-nous ?',
                          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Mon profil',
                    child: GestureDetector(
                      onTap: () => widget.onNavigate(MainScreen.tabProfile),
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: UserAvatar(user: user, radius: 24),
                      ),
                    ),
                  ),
                ],
              ),
              // Annonces promo gérées par l'admin (bandeau défilant).
              FutureBuilder<List<Promotion>>(
                future: _promos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(padding: EdgeInsets.only(top: 20), child: Skeleton(height: 150, radius: 20));
                  }
                  final promos = snapshot.data ?? const <Promotion>[];
                  if (promos.isEmpty) return const _BrandBanner();
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: PromoCarousel(
                      promotions: promos,
                      onTap: (promo) {
                        if (promo.product != null) showProductSheet(context, promo.product!);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _QuickOrderCard(regular: user?.isRegular ?? false, onTap: widget.onStartDelivery),
              const SizedBox(height: 24),
              Text('Nos services', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
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
                    icon: Icons.event_available,
                    title: 'Programmée',
                    description: "Au jour et à l'heure choisis",
                    color: const Color(0xFF7E57C2),
                    onTap: () => _newDelivery(DeliveryType.programmee),
                  ),
                  _ServiceCard(
                    icon: Icons.eco,
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
                  Text('Livraisons récentes', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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

/// Raccourci de commande : envoi par photos (habitué) ou formulaire guidé (nouveau client).
class _QuickOrderCard extends StatelessWidget {
  final bool regular;
  final VoidCallback onTap;

  const _QuickOrderCard({required this.regular, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                child: Icon(regular ? Icons.add_a_photo : Icons.delivery_dining, color: AppColors.onPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      regular ? 'Envoi rapide' : 'Demander une livraison',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      regular
                          ? "Envoyez les photos de vos articles, on s'occupe du reste"
                          : 'Points A et B sur la carte, photos des articles',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bannière de marque affichée quand aucune promo n'est publiée.
class _BrandBanner extends StatelessWidget {
  const _BrandBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/photo_courier.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -0.5)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xE6000000), Color(0x00000000)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Livré vite,\npartout à Lomé',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    SizedBox(height: 6),
                    Text('Colis, courses et produits frais', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ],
                ),
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
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1),
                  ),
                  Text(description,
                      style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
