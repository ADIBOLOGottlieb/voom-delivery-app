import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery.dart';
import '../../models/product.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import '../../utils/formatters.dart';
import 'delivery_detail_screen.dart';
import 'new_delivery_screen.dart';

enum ProductCategory {
  shopping('shopping', 'Shopping', AppColors.primary, AppColors.onPrimary, Icons.shopping_bag),
  agro('agro', 'Agroalimentaire', AppColors.success, AppColors.background, Icons.agriculture);

  const ProductCategory(this.value, this.label, this.color, this.onColor, this.icon);
  final String value;
  final String label;
  final Color color;
  final Color onColor;
  final IconData icon;
}

/// Catalogue de la marketplace (produits gérés par l'admin).
class ProductCatalogScreen extends StatefulWidget {
  final ProductCategory category;

  const ProductCatalogScreen({super.key, required this.category});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  late Future<List<Product>> _products;
  String _search = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _load() =>
      _products = context.read<DeliveryService>().products(category: widget.category.value, search: _search);

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value.trim();
      if (mounted) setState(_load);
    });
  }

  Future<void> _order(Product product) async {
    final quantity = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProductSheet(product: product, color: widget.category.color),
    );
    if (quantity == null || !mounted) return;

    final created = await Navigator.of(context).push<Delivery>(
      MaterialPageRoute(builder: (_) => NewDeliveryScreen(product: product, quantity: quantity)),
    );
    if (created != null && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeliveryDetailScreen(deliveryId: created.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Scaffold(
      appBar: AppBar(title: Text(cat.label), backgroundColor: cat.color, foregroundColor: cat.onColor),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await _products.catchError((_) => <Product>[]);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            FutureBuilder<List<Product>>(
              future: _products,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(snapshot.error.toString(), textAlign: TextAlign.center),
                          TextButton(onPressed: () => setState(_load), child: const Text('Réessayer')),
                        ],
                      ),
                    ),
                  );
                }
                final products = snapshot.data!;
                if (products.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text('Aucun produit disponible.')));
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) => _ProductCard(
                      product: products[i],
                      icon: cat.icon,
                      onTap: () => _order(products[i]),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  final IconData icon;

  const _ProductImage({required this.url, required this.icon});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(icon, size: 48, color: AppColors.textHint),
    );
    if (url == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final IconData icon;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SizedBox(width: double.infinity, child: _ProductImage(url: product.imageUrl, icon: icon))),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (product.vendorName != null)
                    Text(product.vendorName!,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${formatFcfa(product.price)}${product.unit != null ? ' / ${product.unit}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fiche produit + choix de la quantité ; renvoie la quantité choisie.
class _ProductSheet extends StatefulWidget {
  final Product product;
  final Color color;

  const _ProductSheet({required this.product, required this.color});

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (p.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(height: 180, child: _ProductImage(url: p.imageUrl, icon: Icons.image)),
              ),
            const SizedBox(height: 12),
            Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
            if (p.vendorName != null) Text(p.vendorName!, style: Theme.of(context).textTheme.bodyMedium),
            if (p.description != null) ...[
              const SizedBox(height: 8),
              Text(p.description!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton.outlined(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$_quantity ${p.unit ?? ''}', style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton.outlined(
                  onPressed: _quantity < 100 ? () => setState(() => _quantity++) : null,
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text(formatFcfa(p.price * _quantity),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(_quantity),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Commander et me faire livrer'),
            ),
          ],
        ),
      ),
    );
  }
}
