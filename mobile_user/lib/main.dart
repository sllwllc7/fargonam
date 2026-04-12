import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/push_service.dart';
import 'core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/auth_providers.dart';
import 'features/auth/login_screen.dart';
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
  runApp(const ProviderScope(child: FargonamApp()));
}

/// Tema rejimi (light/dark) — global provider.
/// SharedPreferences'da saqlanadi.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSaved();
    return ThemeMode.dark;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? true;
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
    return MaterialApp(
      title: 'Fargonam',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const _Root(),
    );
  }
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Background'dan qaytganda auth va tokenni tekshirish
      ref.read(authControllerProvider.notifier).tryAutoLogin();
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingDone = prefs.getBool('onboarding_done') ?? false;
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _splashDone = true);
    await ref.read(authControllerProvider.notifier).tryAutoLogin();
    if (mounted) setState(() => _authChecked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) return const SplashScreen();
    if (!_onboardingDone) {
      return OnboardingScreen(onDone: () => setState(() => _onboardingDone = true));
    }
    if (!_authChecked) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const LoginScreen();
    return AppShell(key: appShellKey);
  }
}
