import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.user;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Informations utilisateur
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.secondary,
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'Utilisateur',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user?.role?.name.toUpperCase() ?? 'CLIENT',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Menu options
                _ProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'Informations personnelles',
                  subtitle: 'Modifier vos informations',
                  onTap: () {
                    // Navigation vers édition profil
                  },
                ),
                
                _ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Mes adresses',
                  subtitle: 'Gérer vos adresses de livraison',
                  onTap: () {
                    // Navigation vers adresses
                  },
                ),
                
                _ProfileMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Mes commandes',
                  subtitle: 'Historique de vos commandes',
                  onTap: () {
                    // Navigation vers commandes
                  },
                ),
                
                _ProfileMenuItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Mes livraisons',
                  subtitle: 'Suivi de vos livraisons',
                  onTap: () {
                    // Navigation vers livraisons
                  },
                ),
                
                _ProfileMenuItem(
                  icon: Icons.payment_outlined,
                  title: 'Moyens de paiement',
                  subtitle: 'Gérer vos cartes et comptes',
                  onTap: () {
                    // Navigation vers paiements
                  },
                ),
                
                _ProfileMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Paramètres de notification',
                  onTap: () {
                    // Navigation vers notifications
                  },
                ),
                
                _ProfileMenuItem(
                  icon: Icons.help_outline,
                  title: 'Aide et support',
                  subtitle: 'FAQ et contact support',
                  onTap: () {
                    // Navigation vers aide
                  },
                ),
                
                _ProfileMenuItem(
                  icon: Icons.info_outline,
                  title: 'À propos',
                  subtitle: 'Version et informations légales',
                  onTap: () {
                    // Navigation vers à propos
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Bouton de déconnexion
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Déconnexion'),
                          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Déconnexion'),
                            ),
                          ],
                        ),
                      );
                      
                      if (shouldLogout == true) {
                        await authService.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Version de l'app
                Text(
                  'VOOM Delivery v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textHint,
        ),
        onTap: onTap,
      ),
    );
  }
}

