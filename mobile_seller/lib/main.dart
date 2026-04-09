import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/driver/driver_screen.dart';
import 'features/shop/my_shop_screen.dart';

void main() {
  runApp(const ProviderScope(child: FargonamBiznesApp()));
}

class FargonamBiznesApp extends StatelessWidget {
  const FargonamBiznesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fargonam Biznes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
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
    if (!_checked) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const LoginScreen();
    return const _BiznesShell();
  }
}

/// Biznes ilova — 2 tab: Do'kon va Haydovchi
class _BiznesShell extends ConsumerWidget {
  const _BiznesShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fargonam Biznes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.store), text: 'Do\'kon'),
              Tab(icon: Icon(Icons.local_taxi), text: 'Haydovchi'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MyShopScreen(),
            DriverScreen(),
          ],
        ),
      ),
    );
  }
}
