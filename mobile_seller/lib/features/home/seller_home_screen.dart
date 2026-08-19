import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../dashboard/dashboard_screen.dart' show sellerStatsProvider;
import '../orders/seller_orders_screen.dart';
import '../products/add_product_screen.dart';
import '../shop/shop_providers.dart';

/// Seller App "Bosh sahifa" — HANDOFF.md 4-bo'lim: bugungi buyurtmalar soni,
/// tushum, "Yangi buyurtma" bildirishlari. User App home bilan bir xil uslub.
class SellerHomeScreen extends ConsumerWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final shopAsync = ref.watch(myShopProvider);
    final statsAsync = ref.watch(sellerStatsProvider);
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(sellerStatsProvider);
              ref.invalidate(sellerOrdersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                AppSizes.tabBarHeight + AppSizes.tabBarBottomInset,
              ),
              children: [
                Text('ASSALOMU ALAYKUM 👋', style: AppTypography.sectionLabel.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(user?.fullName ?? 'Sotuvchi',
                    style: AppTypography.h1.copyWith(color: AppColors.primaryDark, fontSize: 27)),
                const SizedBox(height: 4),
                shopAsync.when(
                  data: (shop) => Text(
                    shop == null
                        ? ''
                        : (shop.status == ShopStatus.approved
                            ? shop.name
                            : '${shop.name} · tasdiqlanishi kutilmoqda'),
                    style: AppTypography.caption,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),

                // Statistika tili
                statsAsync.when(
                  loading: () => Row(children: [
                    Expanded(child: ShimmerBox(width: double.infinity, height: 96, borderRadius: AppRadius.card)),
                    const SizedBox(width: 10),
                    Expanded(child: ShimmerBox(width: double.infinity, height: 96, borderRadius: AppRadius.card)),
                  ]),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (stats) => Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.receipt_long,
                          label: 'Jami buyurtmalar',
                          value: '${stats['orders'] ?? 0}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.payments_outlined,
                          label: 'Jami tushum',
                          value: formatSom(_toNum(stats['revenue'])),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Yangi mahsulot tezkor tugma
                PressableScale(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    pushAppRoute(context, (_) => const AddProductScreen());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Yangi mahsulot qo\'shish',
                              style: AppTypography.cardTitleSm.copyWith(color: AppColors.primaryDark)),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('YANGI BUYURTMALAR', style: AppTypography.sectionLabel),
                const SizedBox(height: 10),
                ordersAsync.when(
                  loading: () => Column(
                    children: List.generate(
                      3,
                      (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ShimmerBox(width: double.infinity, height: 62, borderRadius: AppRadius.card),
                      ),
                    ),
                  ),
                  error: (_, _) => Text('Yuklanmadi', style: AppTypography.caption),
                  data: (orders) {
                    if (orders.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(child: Text('Hali buyurtma yo\'q', style: AppTypography.caption)),
                      );
                    }
                    final recent = orders.take(5).toList();
                    return Column(children: [for (final o in recent) _RecentOrderTile(order: o)]);
                  },
                ),
              ],
            ),
          ),
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

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 17),
          ),
          const SizedBox(height: 10),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.cardTitle.copyWith(fontSize: 15.5)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});
  final Map<String, dynamic> order;

  static const _labels = {
    'pending': 'Qabul qilindi',
    'preparing': 'Tayyorlanmoqda',
    'ready': 'Tayyor',
    'shipped': 'Kuryerda',
    'delivered': 'Yetkazildi',
    'cancelled': 'Bekor qilingan',
  };

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final label = _labels[status] ?? status;
    final items = (order['items'] as List?) ?? [];
    final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(Icons.receipt_outlined, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order['id']} · ${items.length} mahsulot', style: AppTypography.cardTitleSm.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(formatSom(total), style: AppTypography.price.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(7)),
            child: Text(label, style: AppTypography.small.copyWith(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}
