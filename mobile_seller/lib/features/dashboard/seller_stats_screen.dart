import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:fargonam_ui/theme/legacy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'dashboard_screen.dart' show sellerStatsProvider;

/// "Statistika" tab — HANDOFF.md 4-bo'lim: umumiy savdo ko'rsatkichlari.
/// Kunlik/haftalik taqsimot va eng ko'p sotilgan mahsulotlar hozircha
/// backend'da yo'q (`GET /seller/stats` faqat jami sonlarni beradi) — shu
/// sabab "Tez orada" sifatida belgilangan, soxta grafik chizilmagan.
class SellerStatsScreen extends ConsumerWidget {
  const SellerStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sellerStatsProvider);
    return Scaffold(
      backgroundColor: LegacyColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: LegacyColors.primary,
          backgroundColor: LegacyColors.surface,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(sellerStatsProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
            children: [
              Text('Statistika', style: LegacyTextStyles.h1.copyWith(color: LegacyColors.primaryDark, fontSize: 28)),
              SizedBox(height: 18.h),
              statsAsync.when(
                loading: () => const _StatsGridSkeleton(),
                error: (e, _) => ErrorRetryWidget(error: e, onRetry: () => ref.invalidate(sellerStatsProvider)),
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.payments_outlined,
                            label: 'Jami tushum',
                            value: formatSom(_toNum(stats['revenue'])),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt_long,
                            label: 'Buyurtmalar',
                            value: '${stats['orders'] ?? 0}',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.inventory_2_outlined,
                            label: 'Mahsulotlar',
                            value: '${stats['products'] ?? 0}',
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.storefront_outlined,
                            label: 'Do\'konlar',
                            value: '${stats['shops'] ?? 0}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: LegacyColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: LegacyColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(7.r)),
                      child: Text('Tez orada', style: LegacyTextStyles.small.copyWith(color: LegacyColors.textMuted)),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Kunlik/haftalik savdo va eng ko\'p sotilgan mahsulotlar tahlili',
                        style: LegacyTextStyles.caption,
                      ),
                    ),
                  ],
                ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
            width: 38.w,
            height: 38.w,
            decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
            child: Icon(icon, color: LegacyColors.text, size: 19.sp),
          ),
          SizedBox(height: 12.h),
          Text(value,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: LegacyTextStyles.cardTitle.copyWith(fontSize: 16)),
          SizedBox(height: 2.h),
          Text(label, style: LegacyTextStyles.caption),
        ],
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: ShimmerBox(width: double.infinity, height: 106.h, borderRadius: AppRadius.card)),
          SizedBox(width: 10.w),
          Expanded(child: ShimmerBox(width: double.infinity, height: 106.h, borderRadius: AppRadius.card)),
        ]),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(child: ShimmerBox(width: double.infinity, height: 106.h, borderRadius: AppRadius.card)),
          SizedBox(width: 10.w),
          Expanded(child: ShimmerBox(width: double.infinity, height: 106.h, borderRadius: AppRadius.card)),
        ]),
      ],
    );
  }
}
