import 'dart:ui' as dart_ui;

import 'package:fargonam_ui/fargonam_ui.dart' as ui;
import 'package:fargonam_ui/theme/legacy_tokens.dart' as legacy;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart' show navigatorKey, onTokenExpired, secureStorageProvider;
import 'core/app_config_service.dart';
import 'core/push_service.dart';
import 'core/theme.dart';
import 'core/ws_service.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/telegram_login_screen.dart';
import 'features/driver/driver_screen.dart';
import 'features/home/seller_home_screen.dart';
import 'features/dashboard/seller_stats_screen.dart';
import 'features/orders/seller_orders_screen.dart';
import 'features/products/products_screen.dart';
import 'features/profile/seller_profile_screen.dart';
import 'features/shop/my_shop_screen.dart';
import 'features/shop/shop_providers.dart' show myShopProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init xato: $e');
  }
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) => const ProviderScope(child: FargonamBiznesApp()),
    ),
  );
}

class FargonamBiznesApp extends ConsumerWidget {
  const FargonamBiznesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Token muddati tugaganda login'ga yo'naltirish callback'ini o'rnatish
    onTokenExpired = () {
      ref.read(authControllerProvider.notifier).logout();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TelegramLoginScreen()),
        (route) => false,
      );
    };
    return MaterialApp(
      title: 'Fargonam Biznes',
      debugShowCheckedModeBanner: false,
      theme: ui.AppTheme.lightTheme,
      navigatorKey: navigatorKey,
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
  RemoteConfig _config = RemoteConfig.defaults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final config = await fetchRemoteConfig();
      if (!mounted) return;
      setState(() => _config = config);

      if (await needsForceUpdate(config.minAppVersion)) {
        _showForceUpdateDialog();
        return;
      }

      await ref.read(authControllerProvider.notifier).tryAutoLogin();
      if (mounted) setState(() => _checked = true);
    });
  }

  void _showForceUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yangilanish kerak'),
          content: const Text(
            'Ilovaning yangi versiyasi chiqdi. Davom etish uchun yangilang.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            FilledButton(onPressed: () {}, child: const Text('Yangilash')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_config.maintenanceMode) {
      return _MaintenanceScreen(message: _config.maintenanceMessage);
    }
    if (!_checked) {
      return const Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(
              child: CircularProgressIndicator(color: AppColors.cream)));
    }
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const TelegramLoginScreen();
    return const _RoleRouter();
  }
}

class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.build_outlined,
                      size: 52, color: AppColors.cream),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Texnik ishlar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message.isNotEmpty
                      ? message
                      : 'Texnik ishlar olib borilmoqda.\nTez orada qaytamiz.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      // Tartib HANDOFF.md 4-bo'lim: Market | Buyurtmalar | Bosh sahifa | Statistika | Profil
      pages: [
        const ProductsScreen(),
        const SellerOrdersScreen(),
        const SellerHomeScreen(),
        const SellerStatsScreen(),
        SellerProfileScreen(onLogout: () => onLogout(ref)),
      ],
      ordersTabIndex: 1,
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

class _BiznesShell extends ConsumerStatefulWidget {
  const _BiznesShell({
    required this.pages,
    this.ordersTabIndex,
  });
  final List<Widget> pages;
  // Push bosilganda/WS orqali yangi buyurtma kelganda o'tiladigan tab.
  final int? ordersTabIndex;

  @override
  ConsumerState<_BiznesShell> createState() => _BiznesShellState();
}

class _BiznesShellState extends ConsumerState<_BiznesShell> with WidgetsBindingObserver {
  int _index = 2; // Bosh sahifa default
  SellerOrderEventsWsService? _orderWs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.ordersTabIndex != null) {
      onSellerOrderPushTapped = () {
        HapticFeedback.lightImpact();
        setState(() => _index = widget.ordersTabIndex!);
      };
      _connectOrderWs();
    }
  }

  void _connectOrderWs() {
    _orderWs = SellerOrderEventsWsService(
      onOrderStatus: (payload) {
        ref.invalidate(sellerOrdersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Buyurtma #${payload['order_id']}: holat yangilandi'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
    _orderWs!.connect(ref.read(secureStorageProvider));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.ordersTabIndex == null) return;
    if (state == AppLifecycleState.paused) {
      _orderWs?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _orderWs?.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.ordersTabIndex != null) onSellerOrderPushTapped = null;
    _orderWs?.disconnect();
    super.dispose();
  }

  void _go(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);
    final shop = shopAsync.when(data: (v) => v, error: (_, _) => null, loading: () => null);
    if (shopAsync.hasValue && shop == null) {
      // Hali do'kon yaratilmagan — savdo qilishdan oldin shu shart
      return const MyShopScreen();
    }
    return Scaffold(
      backgroundColor: legacy.LegacyColors.bg,
      body: IndexedStack(index: _index, children: widget.pages),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: dart_ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: legacy.LegacySizes.bottomNav.h,
            decoration: const BoxDecoration(
              color: Color(0xF5FFFFFF),
              border: Border(top: BorderSide(color: legacy.LegacyColors.border)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 8.w, right: 8.w, top: 8.h, bottom: 24.h),
                  child: Row(
                    children: [
                      _SellerNavItem(
                        icon: Icons.storefront_outlined,
                        activeIcon: Icons.storefront,
                        label: 'Market',
                        isActive: _index == 0,
                        onTap: () => _go(0),
                      ),
                      _SellerNavItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long,
                        label: 'Buyurtmalar',
                        isActive: _index == 1,
                        onTap: () => _go(1),
                      ),
                      const Expanded(child: SizedBox()),
                      _SellerNavItem(
                        icon: Icons.insights_outlined,
                        activeIcon: Icons.insights,
                        label: 'Statistika',
                        isActive: _index == 3,
                        onTap: () => _go(3),
                      ),
                      _SellerNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profil',
                        isActive: _index == 4,
                        onTap: () => _go(4),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -18.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _go(2),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52.w,
                            height: 52.w,
                            decoration: BoxDecoration(
                              gradient: _index == 2 ? legacy.LegacyGradients.primary : null,
                              color: _index == 2 ? null : legacy.LegacyColors.textSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: legacy.LegacyColors.surface, width: 4),
                              boxShadow: legacy.LegacyShadows.fab,
                            ),
                            child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Bosh sahifa',
                            style: legacy.LegacyTextStyles.small.copyWith(
                              color: _index == 2 ? legacy.LegacyColors.text : legacy.LegacyColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerNavItem extends StatelessWidget {
  const _SellerNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? legacy.LegacyColors.text : legacy.LegacyColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Column(
            children: [
              Icon(isActive ? activeIcon : icon, color: color, size: 22),
              SizedBox(height: 3.h),
              Text(label, style: legacy.LegacyTextStyles.small.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
