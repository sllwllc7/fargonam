import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:fargonam_ui/theme/legacy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      backgroundColor: LegacyColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: LegacyColors.primary,
          backgroundColor: LegacyColors.surface,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(sellerStatsProvider);
            ref.invalidate(sellerOrdersProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
            children: [
              Text('ASSALOMU ALAYKUM 👋',
                  style: LegacyTextStyles.sectionLabel.copyWith(fontSize: 12)),
              SizedBox(height: 2.h),
              Text(user?.fullName ?? 'Sotuvchi',
                  style: LegacyTextStyles.h1.copyWith(color: LegacyColors.primaryDark, fontSize: 27)),
              SizedBox(height: 4.h),
              shopAsync.when(
                data: (shop) => Text(
                  shop == null
                      ? ''
                      : (shop.status == ShopStatus.approved
                          ? shop.name
                          : '${shop.name} · tasdiqlanishi kutilmoqda'),
                  style: LegacyTextStyles.caption,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              SizedBox(height: 20.h),

              // Statistika tili
              statsAsync.when(
                loading: () => Row(children: [
                  Expanded(child: ShimmerBox(width: double.infinity, height: 96.h, borderRadius: AppRadius.card)),
                  SizedBox(width: 10.w),
                  Expanded(child: ShimmerBox(width: double.infinity, height: 96.h, borderRadius: AppRadius.card)),
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
                    SizedBox(width: 10.w),
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
              SizedBox(height: 14.h),

              // Yangi mahsulot tezkor tugma
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                  decoration: BoxDecoration(
                    color: LegacyColors.sellerAccentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: LegacyColors.sellerAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: const BoxDecoration(color: LegacyColors.sellerAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text('Yangi mahsulot qo\'shish',
                            style: LegacyTextStyles.cardTitleSm.copyWith(color: LegacyColors.primaryDark)),
                      ),
                      Icon(Icons.chevron_right, color: LegacyColors.textSecondary, size: 18.sp),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              Text('YANGI BUYURTMALAR', style: LegacyTextStyles.sectionLabel),
              SizedBox(height: 10.h),
              ordersAsync.when(
                loading: () => Column(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: ShimmerBox(width: double.infinity, height: 62.h, borderRadius: AppRadius.card),
                    ),
                  ),
                ),
                error: (_, _) => Text('Yuklanmadi', style: LegacyTextStyles.caption),
                data: (orders) {
                  if (orders.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: LegacyColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: LegacyColors.border),
                      ),
                      child: Center(child: Text('Hali buyurtma yo\'q', style: LegacyTextStyles.caption)),
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
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: LegacyColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: LegacyColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
            child: Icon(icon, color: LegacyColors.text, size: 17.sp),
          ),
          SizedBox(height: 10.h),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LegacyTextStyles.cardTitle.copyWith(fontSize: 15.5)),
          SizedBox(height: 2.h),
          Text(label, style: LegacyTextStyles.caption.copyWith(fontSize: 11.5)),
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
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: LegacyColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: LegacyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
            child: Icon(Icons.receipt_outlined, color: LegacyColors.text, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order['id']} · ${items.length} mahsulot', style: LegacyTextStyles.cardTitleSm.copyWith(fontSize: 13)),
                SizedBox(height: 2.h),
                Text(formatSom(total), style: LegacyTextStyles.price.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(color: LegacyColors.surfaceAlt, borderRadius: BorderRadius.circular(7.r)),
            child: Text(label, style: LegacyTextStyles.small.copyWith(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}
