import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/driver/driver_screen.dart';
import 'features/orders/seller_orders_screen.dart';
import 'features/products/products_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase init xato: $e');
  }
  runApp(const ProviderScope(child: FargonamBiznesApp()));
}

class FargonamBiznesApp extends StatelessWidget {
  const FargonamBiznesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fargonam Biznes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _Root(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ROOT
// ══════════════════════════════════════════════════════════════

class _Root extends ConsumerStatefulWidget {
  const _Root();
  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authControllerProvider.notifier).tryAutoLogin();
      if (mounted) setState(() => _checked = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(
              child: CircularProgressIndicator(color: AppColors.cream)));
    }
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const LoginScreen();
    return const _RoleRouter();
  }
}

// ══════════════════════════════════════════════════════════════
// ROL ROUTER
// ══════════════════════════════════════════════════════════════

class _RoleRouter extends StatefulWidget {
  const _RoleRouter();
  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  String? _selectedRole;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('biznes_role');
    setState(() {
      _selectedRole = role;
      _loading = false;
    });
  }

  Future<void> _selectRole(String role) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biznes_role', role);
    setState(() => _selectedRole = role);
  }

  Future<void> _logout(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biznes_role');
    await ref.read(authControllerProvider.notifier).logout();
    setState(() => _selectedRole = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(
              child:
                  CircularProgressIndicator(color: AppColors.cream)));
    }

    if (_selectedRole == null) {
      return _RolePickerScreen(onSelect: _selectRole);
    }

    if (_selectedRole == 'driver') {
      return _DriverShell(onLogout: _logout);
    }

    return _SellerShell(onLogout: _logout);
  }
}

// ══════════════════════════════════════════════════════════════
// ROL TANLASH EKRANI
// ══════════════════════════════════════════════════════════════

class _RolePickerScreen extends StatelessWidget {
  const _RolePickerScreen({required this.onSelect});
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cream, AppColors.creamDim],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cream.withValues(alpha: 0.3),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.business_center,
                    size: 42, color: AppColors.midnightIndigo),
              ),
              const SizedBox(height: 28),
              const Text(
                'Fargonam Biznes',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nima qilmoqchisiz?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              _RoleCard(
                icon: Icons.store,
                title: 'Do\'kon ochish',
                subtitle:
                    'Mahsulot soting, buyurtmalarni boshqaring, daromad oling',
                color: AppColors.success,
                onTap: () => onSelect('seller'),
              ),
              const SizedBox(height: 16),

              _RoleCard(
                icon: Icons.local_taxi,
                title: 'Haydovchi bo\'lish',
                subtitle:
                    'Yo\'lovchilarni tashib pul ishlang, o\'z vaqtingizda',
                color: AppColors.warning,
                onTap: () => onSelect('driver'),
              ),

              const Spacer(),
              const Center(
                child: Text(
                  'Keyinroq boshqa rolga o\'tishingiz mumkin',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: widget.color.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    Icon(widget.icon, color: widget.color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textMuted.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SELLER SHELL
// ══════════════════════════════════════════════════════════════

class _SellerShell extends ConsumerWidget {
  const _SellerShell({required this.onLogout});
  final Future<void> Function(WidgetRef ref) onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BiznesShell(
      pages: const [
        DashboardScreen(),
        SellerOrdersScreen(),
        ProductsScreen(),
      ],
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard'),
        NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Buyurtmalar'),
        NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Mahsulotlar'),
      ],
      onLogout: () => onLogout(ref),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DRIVER SHELL
// ══════════════════════════════════════════════════════════════

class _DriverShell extends ConsumerWidget {
  const _DriverShell({required this.onLogout});
  final Future<void> Function(WidgetRef ref) onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Fargonam Haydovchi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              onLogout(ref);
            },
          ),
        ],
      ),
      body: const DriverScreen(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BIZNES SHELL
// ══════════════════════════════════════════════════════════════

class _BiznesShell extends StatefulWidget {
  const _BiznesShell({
    required this.pages,
    required this.destinations,
    required this.onLogout,
  });
  final List<Widget> pages;
  final List<NavigationDestination> destinations;
  final VoidCallback onLogout;

  @override
  State<_BiznesShell> createState() => _BiznesShellState();
}

class _BiznesShellState extends State<_BiznesShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: widget.pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
        destinations: widget.destinations,
      ),
    );
  }
}
