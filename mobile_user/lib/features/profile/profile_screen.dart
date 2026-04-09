import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../auth/auth_providers.dart';
import '../favorites/favorites_screen.dart';
import '../orders/orders_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + ism
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    (user.fullName ?? user.phone).substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName ?? 'Foydalanuvchi',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(user.phone, style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Menyular
          _MenuItem(
            icon: Icons.receipt_long,
            title: 'Buyurtmalarim',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage())),
          ),
          _MenuItem(
            icon: Icons.favorite_border,
            title: 'Sevimlilar',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
          _MenuItem(
            icon: Icons.location_on_outlined,
            title: 'Manzillarim',
            onTap: () {},
            badge: 'Tez orada',
          ),
          _MenuItem(
            icon: Icons.edit,
            title: 'Ismni o\'zgartirish',
            onTap: () async {
              final ctrl = TextEditingController(text: user.fullName ?? '');
              final newName = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Ismni o\'zgartirish'),
                  content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Yangi ism')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
                    TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Saqlash')),
                  ],
                ),
              );
              if (newName != null) {
                await ref.read(dioProvider).patch('/auth/me', queryParameters: {'full_name': newName});
                await ref.read(authControllerProvider.notifier).tryAutoLogin();
              }
            },
          ),
          _MenuItem(
            icon: Icons.local_taxi_outlined,
            title: 'Sayohat tarixim',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _RideHistoryScreen())),
          ),
          _MenuItem(
            icon: Icons.lock_outline,
            title: 'Parolni o\'zgartirish',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ChangePasswordScreen())),
          ),
          _MenuItem(
            icon: Icons.help_outline,
            title: 'Yordam',
            onTap: () {},
          ),
          const SizedBox(height: 20),
          // Chiqish
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Chiqish', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Fargonam v0.1.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.title, required this.onTap, this.badge});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.secondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(badge!, style: const TextStyle(fontSize: 11, color: AppTheme.secondary, fontWeight: FontWeight.w600)),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}

/// Buyurtmalar alohida sahifada ochiladi.
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const OrdersScreen();
  }
}

class _ChangePasswordScreen extends ConsumerStatefulWidget {
  const _ChangePasswordScreen();
  @override
  ConsumerState<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<_ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_oldCtrl.text.isEmpty || _newCtrl.text.length < 6) {
      setState(() => _error = 'Yangi parol kamida 6 belgi');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await ref.read(dioProvider).post('/auth/change-password',
          queryParameters: {'old_password': _oldCtrl.text, 'new_password': _newCtrl.text});
      setState(() => _success = 'Parol muvaffaqiyatli o\'zgartirildi!');
      _oldCtrl.clear();
      _newCtrl.clear();
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parolni o\'zgartirish')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _oldCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'Eski parol', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 14),
            TextField(controller: _newCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'Yangi parol', prefixIcon: Icon(Icons.lock))),
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: AppTheme.accent))],
            if (_success != null) ...[const SizedBox(height: 12), Text(_success!, style: const TextStyle(color: Colors.green))],
            const SizedBox(height: 20),
            FilledButton(onPressed: _loading ? null : _submit, child: const Text('O\'zgartirish')),
          ],
        ),
      ),
    );
  }
}

final _rideHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/rides/my');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class _RideHistoryScreen extends ConsumerWidget {
  const _RideHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(_rideHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sayohat tarixim')),
      body: ridesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xato: $e')),
        data: (rides) {
          if (rides.isEmpty) {
            return const Center(child: Text('Hali sayohat yo\'q'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, i) {
              final r = rides[i];
              final status = r['status'] as String;
              Color color = Colors.grey;
              String label = status;
              if (status == 'completed') { color = Colors.green; label = 'Tugadi'; }
              if (status == 'cancelled') { color = Colors.red; label = 'Bekor'; }
              if (status == 'searching') { color = Colors.orange; label = 'Qidirilmoqda'; }
              if (status == 'in_progress') { color = Colors.indigo; label = 'Yo\'lda'; }
              if (status == 'accepted') { color = Colors.blue; label = 'Qabul qilindi'; }
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('#${r['id']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(r['pickup_address'] as String, style: const TextStyle(fontSize: 13)),
                      Text(r['destination_address'] as String, style: const TextStyle(fontSize: 13)),
                      if (r['fare'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('${r['fare']} so\'m', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

