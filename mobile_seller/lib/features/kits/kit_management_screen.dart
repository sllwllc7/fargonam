import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:fargonam_ui/theme/legacy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      backgroundColor: LegacyColors.bg,
      appBar: AppBar(backgroundColor: LegacyColors.bg, title: Text('Sinf to\'plamlari', style: LegacyTextStyles.title)),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: LegacyColors.primary)),
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
      final created =
          await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AddKitScreen(shopId: shopId)));
      if (created == true) ref.invalidate(shopKitsProvider(shopId));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: LegacyColors.sellerAccent,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: addKit,
        child: const Icon(Icons.add, size: 28),
      ),
      body: kitsAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: List.generate(
              4,
              (_) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: ShimmerBox(width: double.infinity, height: 78.h, borderRadius: AppRadius.card),
              ),
            ),
          ),
        ),
        error: (e, _) => ErrorRetryWidget(error: e, onRetry: () => ref.invalidate(shopKitsProvider(shopId))),
        data: (kits) {
          if (kits.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96.w,
                      height: 96.w,
                      decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                      child: Icon(Icons.class_outlined, size: 42.sp, color: LegacyColors.textMuted),
                    ),
                    SizedBox(height: 20.h),
                    Text('Hali to\'plam yo\'q', style: LegacyTextStyles.cardTitle),
                    SizedBox(height: 8.h),
                    Text('Pastdagi tugma bilan birinchi sinf to\'plamini yarating',
                        textAlign: TextAlign.center, style: LegacyTextStyles.body.copyWith(color: LegacyColors.textSecondary)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
            itemCount: kits.length,
            separatorBuilder: (_, _) => SizedBox(height: 10.h),
            itemBuilder: (context, i) => _KitTile(shopId: shopId, kit: kits[i]),
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
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final edited = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => AddKitScreen(shopId: shopId, editingKit: kit)),
        );
        if (edited == true) ref.invalidate(shopKitsProvider(shopId));
      },
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: LegacyColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: LegacyColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
              child: Center(
                child: Text(kit.gradeLevel ?? '?',
                    style: LegacyTextStyles.cardTitle.copyWith(color: LegacyColors.text, fontSize: 18)),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kit.name, style: LegacyTextStyles.cardTitleSm),
                  SizedBox(height: 4.h),
                  Text('${kit.items.length} xil · ${formatSom(kit.total)}', style: LegacyTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 18.sp, color: LegacyColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
