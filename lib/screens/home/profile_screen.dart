import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../../utils/launchers.dart';
import '../auth/login_screen.dart';

/// Profil (partagé par le client et le livreur).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const supportPhone = '+22890000000';

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Déconnexion')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    await context.read<AuthService>().logout();
    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.secondary,
                  child: Text(user?.initial ?? 'U',
                      style: textTheme.headlineMedium?.copyWith(color: AppColors.primary)),
                ),
                const SizedBox(height: 16),
                Text(user?.name ?? 'Utilisateur',
                    style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user?.phoneNumber ?? '', style: textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary)),
                if (user?.email != null)
                  Text(user!.email!, style: textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    (user?.roleLabel ?? 'Client').toUpperCase(),
                    style: textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                if (user?.vehicle != null) ...[
                  const SizedBox(height: 8),
                  Text(user!.vehicle!, style: textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text("Contacter l'agence"),
              subtitle: const Text(supportPhone),
              trailing: const Icon(Icons.call),
              onTap: () => callPhone(context, supportPhone),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('À propos'),
              subtitle: Text('VOOM Delivery · Lomé, Togo · v1.0.0'),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
