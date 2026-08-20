import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart' show navigatorKey, onTokenExpired, secureStorageProvider;
import 'core/app_config_service.dart';
import 'core/app_update_service.dart';
import 'core/push_service.dart';
import 'core/widgets/app_update_sheet.dart';
import 'core/ws_service.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/telegram_login_screen.dart';
import 'features/dashboard/seller_stats_screen.dart';
import 'features/driver/driver_screen.dart';
import 'features/home/seller_home_screen.dart';
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
  runApp(const ProviderScope(child: FargonamBiznesApp()));
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
      theme: AppTheme.lightTheme,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final info = await checkForUpdate('seller');
    if (info != null && mounted) {
      showAppUpdateSheet(context, info);
    }
  }

  void _showForceUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
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
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
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
      backgroundColor: AppColors.background,
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
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
                  child: const Icon(Icons.build_outlined, size: 52, color: AppColors.primary),
                ),
                const SizedBox(height: 28),
                Text('Texnik ishlar', style: AppTypography.h2),
                const SizedBox(height: 12),
                Text(
                  message.isNotEmpty ? message : 'Texnik ishlar olib borilmoqda.\nTez orada qaytamiz.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: AppColors.textMuted),
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
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(gradient: AppGradients.cta, borderRadius: BorderRadius.circular(AppRadius.cardLarge), boxShadow: AppShadows.cta),
                  child: const Icon(Icons.business_center, size: 42, color: AppColors.ctaText),
                ),
                const SizedBox(height: 28),
                Text('Fargonam Biznes', style: AppTypography.h1),
                const SizedBox(height: 8),
                Text('Nima qilmoqchisiz?', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 40),
                _RoleCard(
                  icon: Icons.store,
                  title: 'Do\'kon ochish',
                  subtitle: 'Mahsulot soting, buyurtmalarni boshqaring, daromad oling',
                  color: AppColors.success,
                  onTap: () => onSelect('seller'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.local_taxi,
                  title: 'Haydovchi bo\'lish',
                  subtitle: 'Yo\'lovchilarni tashib pul ishlang, o\'z vaqtingizda',
                  color: AppColors.warning,
                  onTap: () => onSelect('driver'),
                ),
                const Spacer(),
                Center(
                  child: Text('Keyinroq boshqa rolga o\'tishingiz mumkin', style: AppTypography.small.copyWith(color: AppColors.textMuted)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(AppRadius.card)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.caption.copyWith(height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted.withValues(alpha: 0.6)),
          ],
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
      backgroundColor: AppColors.background,
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
// BIZNES SHELL — FloatingTabBar (fargonam_ui, mobile_user bilan bir xil)
// ══════════════════════════════════════════════════════════════

const _sellerTabItems = [
  FloatingTabItem(icon: _sellerMarketIcon, label: 'Market'),
  FloatingTabItem(icon: _sellerOrdersIcon, label: 'Buyurtmalar'),
  FloatingTabItem(icon: TabIcons.home, label: 'Bosh sahifa'),
  FloatingTabItem(icon: _sellerStatsIcon, label: 'Statistika'),
  FloatingTabItem(icon: TabIcons.profile, label: 'Profil'),
];
const _sellerMarketIcon = TabIcons.market;
const _sellerOrdersIcon =
    '<svg viewBox="0 0 24 24"><path d="M6 3.5h12v17l-2-1.3-2 1.3-2-1.3-2 1.3-2-1.3-2 1.3zM9 8h6M9 11.5h6M9 15h3.5" stroke="#000" stroke-width="1.9" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';
const _sellerStatsIcon =
    '<svg viewBox="0 0 24 24"><path d="M4 20V10M10 20V4M16 20v-7M4 20h16" stroke="#000" stroke-width="1.9" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';

class _BiznesShell extends ConsumerStatefulWidget {
  const _BiznesShell({required this.pages, this.ordersTabIndex});
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(index: _index, children: widget.pages),
          FloatingTabBar(activeIndex: _index, onTap: _go, items: _sellerTabItems),
        ],
      ),
    );
  }
}
