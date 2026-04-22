import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_providers.dart';
import '../legal/legal_screen.dart';
import '../orders/seller_orders_screen.dart';
import '../shop/my_shop_screen.dart';
import '../shop/shop_providers.dart' show myShopProvider;

final sellerStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(dioProvider).get('/seller/stats');
  return res.data as Map<String, dynamic>;
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sellerStatsProvider);
    final user = ref.watch(authControllerProvider).user;
    final ordersAsync = ref.watch(sellerOrdersProvider);
    final shopAsync = ref.watch(myShopProvider);

    final shop = shopAsync.when(
        data: (v) => v, error: (_, _) => null, loading: () => null);
    if (shopAsync.hasValue && shop == null) {
      return const MyShopScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Salom, ${user?.fullName ?? 'Sotuvchi'}!'),
      ),
      body: RefreshIndicator(
        color: AppColors.cream,
        backgroundColor: AppColors.surfaceHigh,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.invalidate(sellerStatsProvider);
          ref.invalidate(sellerOrdersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Statistika kartalari
            statsAsync.when(
              loading: () => const _StatsSkeleton(),
              error: (e, _) => _ErrorCard(text: 'Statistika: $e'),
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                        icon: Icons.monetization_on,
                        label: 'Daromad',
                        value: formatPrice(_toNum(stats['revenue'])),
                        color: AppColors.success,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        icon: Icons.receipt_long,
                        label: 'Buyurtmalar',
                        value: '${stats['orders']}',
                        color: AppColors.info,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                        icon: Icons.inventory_2,
                        label: 'Mahsulotlar',
                        value: '${stats['products']}',
                        color: AppColors.warning,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        icon: Icons.store,
                        label: 'Do\'konlar',
                        value: '${stats['shops']}',
                        color: AppColors.cream,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Oxirgi buyurtmalar
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'OXIRGI BUYURTMALAR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ordersAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ShimmerBox(
                      width: double.infinity,
                      height: 70,
                      borderRadius: 16,
                    ),
                  ),
                ),
              ),
              error: (_, _) => const Text(
                'Yuklanmadi',
                style: TextStyle(color: AppColors.textMuted),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.divider, width: 0.5),
                    ),
                    child: const Center(
                      child: Text(
                        'Hali buyurtma yo\'q',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14),
                      ),
                    ),
                  );
                }
                final recent = orders.take(5).toList();
                return Column(
                  children: [
                    for (final o in recent) _RecentOrderTile(order: o),
                  ],
                );
              },
            ),

            // Qoidalar
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LegalScreen())),
                  child: const Text(
                    'Foydalanish shartlari',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                const Text('·',
                    style: TextStyle(color: AppColors.textMuted)),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const LegalScreen(initialTab: 1))),
                  child: const Text(
                    'Maxfiylik siyosati',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static double _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ── Stat card ──

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
                child: ShimmerBox(
                    width: double.infinity,
                    height: 110,
                    borderRadius: 20)),
            SizedBox(width: 12),
            Expanded(
                child: ShimmerBox(
                    width: double.infinity,
                    height: 110,
                    borderRadius: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
                child: ShimmerBox(
                    width: double.infinity,
                    height: 110,
                    borderRadius: 20)),
            SizedBox(width: 12),
            Expanded(
                child: ShimmerBox(
                    width: double.infinity,
                    height: 110,
                    borderRadius: 20)),
          ],
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final (label, color) = switch (status) {
      'pending' => ('Kutilmoqda', AppColors.warning),
      'paid' => ('To\'langan', AppColors.info),
      'shipped' => ('Yo\'lda', AppColors.info),
      'delivered' => ('Yetkazildi', AppColors.success),
      'cancelled' => ('Bekor', AppColors.error),
      _ => (status, AppColors.textMuted),
    };
    final items = (order['items'] as List?) ?? [];
    final totalStr = order['total']?.toString() ?? '0';
    final total = double.tryParse(totalStr) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order['id']}  •  ${items.length} mahsulot',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPrice(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
