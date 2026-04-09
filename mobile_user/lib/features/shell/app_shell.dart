import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../home/home_feed_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../taxi/taxi_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';

/// Global key — bosh sahifadan tab o'zgartirish uchun.
final appShellKey = GlobalKey<AppShellState>();

/// Asosiy ilova qobig'i — 5 ta tab.
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  AppShellState createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _index = 0;

  void switchTab(int index) => setState(() => _index = index);

  final _pages = const [
    HomeFeedScreen(),
    MarketplaceScreen(),
    TaxiScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Asosiy'),
          const NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Do\'konlar'),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.local_taxi, color: Colors.white, size: 22),
            ),
            label: 'Taksi',
          ),
          const NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Savatcha'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
