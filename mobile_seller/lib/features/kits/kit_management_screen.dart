import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shop/shop_providers.dart' show myShopProvider;
import 'add_kit_screen.dart';
import 'kit_providers.dart';

/// "Sinf to'plamlari" — HANDOFF.md 4-bo'lim, 5-band. Sotuvchi 1-11 sinflar
/// uchun tayyor to'plamlarni shu yerda yaratadi/tahrirlaydi.
class KitManagementScreen extends ConsumerWidget {
  const KitManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(myShopProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: Text('Sinf to\'plamlari', style: AppTypography.title)),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorRetryWidget(error: e, onRetry: () => ref.invalidate(myShopProvider)),
        data: (shop) {
          if (shop == null) return const SizedBox.shrink();
          return _KitList(shopId: shop.id);
        },
      ),
    );
  }
}

class _KitList extends ConsumerWidget {
  const _KitList({required this.shopId});
  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kitsAsync = ref.watch(shopKitsProvider(shopId));

    Future<void> addKit() async {
      HapticFeedback.lightImpact();
      final created = await pushAppRoute<bool>(context, (_) => AddKitScreen(shopId: shopId));
      if (created == true) ref.invalidate(shopKitsProvider(shopId));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.warning,
        foregroundColor: AppColors.surface,
        shape: const CircleBorder(),
        onPressed: addKit,
        child: const Icon(Icons.add, size: 28),
      ),
      body: kitsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: const ShimmerBox(width: double.infinity, height: 78, borderRadius: AppRadius.card),
              ),
            ),
          ),
        ),
        error: (e, _) => ErrorRetryWidget(error: e, onRetry: () => ref.invalidate(shopKitsProvider(shopId))),
        data: (kits) {
          if (kits.isEmpty) {
            return ScreenFadeIn(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                        child: const Icon(Icons.class_outlined, size: 42, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),
                      Text('Hali to\'plam yo\'q', style: AppTypography.cardTitle),
                      const SizedBox(height: 8),
                      Text('Pastdagi tugma bilan birinchi sinf to\'plamini yarating',
                          textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            );
          }
          return ScreenFadeIn(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: kits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => FadeUpItem(
                delay: AppMotion.staggerStep * i,
                child: _KitTile(shopId: shopId, kit: kits[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KitTile extends ConsumerWidget {
  const _KitTile({required this.shopId, required this.kit});
  final int shopId;
  final Kit kit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PressableScale(
      onTap: () async {
        HapticFeedback.lightImpact();
        final edited = await pushAppRoute<bool>(context, (_) => AddKitScreen(shopId: shopId, editingKit: kit));
        if (edited == true) ref.invalidate(shopKitsProvider(shopId));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Center(
                child: Text(kit.gradeLevel ?? '?',
                    style: AppTypography.cardTitle.copyWith(color: AppColors.primaryDeep, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kit.name, style: AppTypography.cardTitleSm, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${kit.items.length} xil · ${formatSom(kit.total)}', style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
