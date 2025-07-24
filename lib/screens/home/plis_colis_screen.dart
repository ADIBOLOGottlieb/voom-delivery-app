import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class PlisColisScreen extends StatelessWidget {
  const PlisColisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plis & Colis'),
        backgroundColor: AppColors.info,
        foregroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Services de livraison
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.info,
                    AppColors.info.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: AppColors.background,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service de Livraison',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.background,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rapide, sûr et fiable',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.background,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Types de livraison
            Text(
              'Types de Livraison',
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
              childAspectRatio: 1.2,
              children: [
                _DeliveryTypeCard(
                  icon: Icons.mail,
                  title: 'Plis',
                  description: 'Documents et courriers',
                  color: AppColors.primary,
                  onTap: () {
                    _showDeliveryForm(context, 'Plis');
                  },
                ),
                _DeliveryTypeCard(
                  icon: Icons.inventory,
                  title: 'Colis',
                  description: 'Packages et objets',
                  color: AppColors.info,
                  onTap: () {
                    _showDeliveryForm(context, 'Colis');
                  },
                ),
                _DeliveryTypeCard(
                  icon: Icons.flash_on,
                  title: 'Express',
                  description: 'Livraison en 2h',
                  color: AppColors.warning,
                  onTap: () {
                    _showDeliveryForm(context, 'Express');
                  },
                ),
                _DeliveryTypeCard(
                  icon: Icons.schedule,
                  title: 'Programmée',
                  description: 'À une heure précise',
                  color: AppColors.success,
                  onTap: () {
                    _showDeliveryForm(context, 'Programmée');
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Mes livraisons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes Livraisons',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Liste des livraisons
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return _DeliveryCard(
                  id: 'VD${1000 + index}',
                  type: index == 0 ? 'Colis' : index == 1 ? 'Plis' : 'Express',
                  status: index == 0 ? 'En cours' : index == 1 ? 'Livré' : 'En attente',
                  from: 'Lomé Centre',
                  to: 'Kégué',
                  date: '24 Juil 2025',
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showDeliveryForm(context, 'Nouvelle');
        },
        backgroundColor: AppColors.info,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Livraison'),
      ),
    );
  }

  void _showDeliveryForm(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeliveryFormSheet(type: type),
    );
  }
}

class _DeliveryTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _DeliveryTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String id;
  final String type;
  final String status;
  final String from;
  final String to;
  final String date;

  const _DeliveryCard({
    required this.id,
    required this.type,
    required this.status,
    required this.from,
    required this.to,
    required this.date,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Livré':
        return AppColors.success;
      case 'En cours':
        return AppColors.warning;
      case 'En attente':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#$id',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  from,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  to,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryFormSheet extends StatefulWidget {
  final String type;

  const _DeliveryFormSheet({required this.type});

  @override
  State<_DeliveryFormSheet> createState() => _DeliveryFormSheetState();
}

class _DeliveryFormSheetState extends State<_DeliveryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nouvelle Livraison - ${widget.type}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse de départ',
                        prefixIcon: Icon(Icons.my_location),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir l\'adresse de départ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse de destination',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir l\'adresse de destination';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description du colis/pli',
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Demande de livraison créée avec succès'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: AppColors.background,
                        ),
                        child: const Text('Créer la demande'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

