import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: FargonamApp()));
}

class FargonamApp extends StatelessWidget {
  const FargonamApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fargonam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerStatefulWidget {
  const _Root();
  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  bool _splashDone = false;
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Splash minimum 2 soniya ko'rsatiladi
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _splashDone = true);
    await ref.read(authControllerProvider.notifier).tryAutoLogin();
    if (mounted) setState(() => _authChecked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) return const SplashScreen();
    if (!_authChecked) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const LoginScreen();
    return AppShell(key: appShellKey);
  }
}
