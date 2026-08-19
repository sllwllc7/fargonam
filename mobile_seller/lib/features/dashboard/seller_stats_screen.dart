import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(sellerStatsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                AppSizes.tabBarHeight + AppSizes.tabBarBottomInset,
              ),
              children: [
                Text('Statistika', style: AppTypography.h1.copyWith(color: AppColors.primaryDark, fontSize: 28)),
                const SizedBox(height: 18),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.receipt_long,
                              label: 'Buyurtmalar',
                              value: '${stats['orders'] ?? 0}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.inventory_2_outlined,
                              label: 'Mahsulotlar',
                              value: '${stats['products'] ?? 0}',
                            ),
                          ),
                          const SizedBox(width: 10),
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
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(7)),
                        child: Text('Tez orada', style: AppTypography.small.copyWith(color: AppColors.textMuted)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kunlik/haftalik savdo va eng ko\'p sotilgan mahsulotlar tahlili',
                          style: AppTypography.caption,
                        ),
                      ),
                    ],
                  ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(height: 12),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption),
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
          Expanded(child: ShimmerBox(width: double.infinity, height: 106, borderRadius: AppRadius.card)),
          const SizedBox(width: 10),
          Expanded(child: ShimmerBox(width: double.infinity, height: 106, borderRadius: AppRadius.card)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ShimmerBox(width: double.infinity, height: 106, borderRadius: AppRadius.card)),
          const SizedBox(width: 10),
          Expanded(child: ShimmerBox(width: double.infinity, height: 106, borderRadius: AppRadius.card)),
        ]),
      ],
    );
  }
}
