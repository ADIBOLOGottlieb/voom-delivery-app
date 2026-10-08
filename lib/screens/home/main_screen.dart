import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import 'home_screen.dart';
import 'plis_colis_screen.dart';
import 'product_catalog_screen.dart';
import 'profile_screen.dart';

/// Navigation principale du client.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const tabHome = 0;
  static const tabShopping = 1;
  static const tabAgro = 2;
  static const tabDeliveries = 3;
  static const tabProfile = 4;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = MainScreen.tabHome;

  void _goTo(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigate: _goTo),
      const ProductCatalogScreen(category: ProductCategory.shopping),
      const ProductCatalogScreen(category: ProductCategory.agro),
      const PlisColisScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      // Barre Material 3 : fond noir, pastille jaune sur l'onglet actif.
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.secondary,
          indicatorColor: AppColors.primary,
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11.5,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? AppColors.primary : Colors.white70,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? AppColors.onPrimary : Colors.white70,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _goTo,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
            NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag), label: 'Shopping'),
            NavigationDestination(
                icon: Icon(Icons.agriculture_outlined), selectedIcon: Icon(Icons.agriculture), label: 'Agro'),
            NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Colis'),
            NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
