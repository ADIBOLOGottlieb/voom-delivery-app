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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _goTo,
        backgroundColor: AppColors.secondary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.surface,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Shopping'),
          BottomNavigationBarItem(
              icon: Icon(Icons.agriculture_outlined), activeIcon: Icon(Icons.agriculture), label: 'Agro'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping), label: 'Plis & Colis'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
