import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class AgroScreen extends StatelessWidget {
  const AgroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agroalimentaire'),
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filtres
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière promotionnelle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success,
                    AppColors.success.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produits Frais du Jour',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Directement des producteurs locaux',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.success,
                    ),
                    child: const Text('Découvrir'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Catégories agricoles
            Text(
              'Catégories',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _AgroCategoryCard(
                  icon: Icons.eco,
                  title: 'Fruits & Légumes',
                  subtitle: '120+ produits',
                  color: AppColors.success,
                ),
                _AgroCategoryCard(
                  icon: Icons.grain,
                  title: 'Céréales',
                  subtitle: '45+ produits',
                  color: AppColors.warning,
                ),
                _AgroCategoryCard(
                  icon: Icons.local_drink,
                  title: 'Produits Laitiers',
                  subtitle: '30+ produits',
                  color: AppColors.info,
                ),
                _AgroCategoryCard(
                  icon: Icons.restaurant,
                  title: 'Épices',
                  subtitle: '25+ produits',
                  color: AppColors.error,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Producteurs locaux
            Text(
              'Producteurs Locaux',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _ProducerCard(
                    name: 'Producteur ${index + 1}',
                    location: 'Région ${index + 1}',
                    rating: 4.5 + (index * 0.1),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Produits recommandés
            Text(
              'Recommandés pour vous',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return _AgroProductCard(
                  name: 'Tomates fraîches bio',
                  producer: 'Ferme Locale ${index + 1}',
                  price: '${(index + 1) * 500} FCFA/kg',
                  rating: 4.8,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AgroCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AgroCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProducerCard extends StatelessWidget {
  final String name;
  final String location;
  final double rating;

  const _ProducerCard({
    required this.name,
    required this.location,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.success.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                location,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    size: 12,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgroProductCard extends StatelessWidget {
  final String name;
  final String producer;
  final String price;
  final double rating;

  const _AgroProductCard({
    required this.name,
    required this.producer,
    required this.price,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco,
                color: AppColors.success,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    producer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.background,
                    minimumSize: const Size(80, 32),
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

