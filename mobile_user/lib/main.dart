import 'package:fargonam_ui/fargonam_ui.dart' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/app_config_service.dart';
import 'core/navigator_key.dart';
import 'core/push_service.dart';
import 'core/theme/app_colors.dart';
import 'core/user_name_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/auth_providers.dart';
import 'features/auth/telegram_login_screen.dart';
import 'features/onboarding/name_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Yandex MapKit native MainApplication.kt'da boshlanadi
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Crashlytics — barcha Flutter xatolarini ushlaydi
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase init xato (push/crashlytics ishlamaydi): $e');
  }
  // Rasm keshi — 200 MB, 1000 ta rasm
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  // 5.4: status bar shaffof, ikonkalar dark (fon och rangda — #EEF1F6).
  // Navy sarlavhali ekranlar o'zining AnnotatedRegion bilan ustidan bosadi.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) => const ProviderScope(child: FargonamApp()),
    ),
  );
}

/// Tema rejimi (light/dark) — global provider.
/// SharedPreferences'da saqlanadi.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSaved();
    return ThemeMode.light;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', dark);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class FargonamApp extends ConsumerWidget {
  const FargonamApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Token muddati tugaganda login'ga yo'naltirish callback'ini o'rnatish
    onTokenExpired = () {
      ref.read(authControllerProvider.notifier).logout();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TelegramLoginScreen()),
        (route) => false,
      );
    };
    return MaterialApp(
      title: 'Fargonam',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ui.AppTheme.lightTheme,
      // Prototipda dark-mode yo'q — darkTheme lightTheme bilan bir xil
      // (5.5, 7-bo'lim). Sozlamalardagi almashtirgich hozircha
      // qoladi, lekin ko'rinishga ta'sir qilmaydi.
      darkTheme: ui.AppTheme.darkTheme,
      themeMode: themeMode,
      scrollBehavior: const _AppScrollBehavior(),
      home: const _Root(),
    );
  }
}

/// 5.4: Android overscroll ko'k porlashi o'chiriladi, `ClampingScrollPhysics`.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

class _Root extends ConsumerStatefulWidget {
  const _Root();
  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> with WidgetsBindingObserver {
  bool _splashDone = false;
  bool _authChecked = false;
  bool _onboardingDone = false;
  RemoteConfig _config = RemoteConfig.defaults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime? _lastResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 10 daqiqada bir marta token tekshirish — har safar emas
      final now = DateTime.now();
      if (_lastResumed == null || now.difference(_lastResumed!).inMinutes >= 10) {
        _lastResumed = now;
        ref.read(authControllerProvider.notifier).tryAutoLogin();
      }
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingDone = prefs.getBool('onboarding_done') ?? false;

    // Remote config va splash parallel yuklanadi
    final results = await Future.wait([
      fetchRemoteConfig(),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);
    final config = results[0] as RemoteConfig;
    if (mounted) {
      setState(() {
        _config = config;
        _splashDone = true;
      });
    }

    // Majburiy yangilash tekshiruvi
    if (mounted && await needsForceUpdate(config.minAppVersion)) {
      _showForceUpdateDialog();
      return;
    }

    await ref.read(authControllerProvider.notifier).tryAutoLogin();
    if (mounted) setState(() => _authChecked = true);
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
            FilledButton(
              onPressed: () {},
              child: const Text('Yangilash'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) return const SplashScreen();
    if (_config.maintenanceMode) return _MaintenanceScreen(message: _config.maintenanceMessage);
    if (!_onboardingDone) {
      return OnboardingScreen(onDone: () => setState(() => _onboardingDone = true));
    }
    if (!_authChecked) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const TelegramLoginScreen();

    final nameAsync = ref.watch(userNameProvider);
    return nameAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => AppShell(key: appShellKey),
      data: (name) {
        if (name == null) {
          return NameScreen(onDone: () => setState(() {}));
        }
        return AppShell(key: appShellKey);
      },
    );
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
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.build_outlined,
                      size: 52, color: AppColors.primary),
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
