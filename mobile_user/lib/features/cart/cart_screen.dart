import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../checkout/checkout_screen.dart';
import '../shell/app_shell.dart' show appShellKey;

final cartProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/cart');
  return (res.data as List).cast<Map<String, dynamic>>();
});

/// Savat — HANDOFF.md 2-bo'lim, 6-band.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: cartAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Yuklab bo\'lmadi', style: AppTextStyles.caption)),
          data: (items) {
            double total = 0;
            int totalQty = 0;
            for (final ci in items) {
              final price = double.tryParse(ci['product_price']?.toString() ?? '') ?? 0;
              final qty = (ci['quantity'] as int?) ?? 0;
              total += price * qty;
              totalQty += qty;
            }

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.maybePop(context);
                        },
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                          child: Icon(Icons.arrow_back_ios_new, size: 15.sp, color: AppColors.text),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Savat', style: AppTextStyles.h2.copyWith(fontSize: 23)),
                          Text(totalQty > 0 ? '$totalQty ta mahsulot' : 'Bo\'sh', style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  Expanded(child: _EmptyCart())
                else ...[
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        ref.invalidate(cartProvider);
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10.h),
                        itemBuilder: (context, i) => _CartItemCard(item: items[i]),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
                    decoration: const BoxDecoration(
                      color: Color(0xF0FFFFFF),
                      border: Border(top: BorderSide(color: Color(0x0D000000))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Yetkazib berish', style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 13.5)),
                            Text('Bepul', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5)),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Jami', style: AppTextStyles.h2.copyWith(fontSize: 17)),
                            Text(formatSom(total), style: AppTextStyles.h2.copyWith(fontSize: 17)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                          },
                          child: Container(
                            height: 54.h,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: BorderRadius.circular(17.r),
                              boxShadow: AppShadows.primaryButton,
                            ),
                            child: Center(child: Text('Buyurtmani rasmiylashtirish', style: AppTextStyles.button)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              child: Icon(Icons.shopping_bag_outlined, size: 40.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 20.h),
            Text('Savat bo\'sh', style: AppTextStyles.cardTitle.copyWith(fontSize: 17)),
            SizedBox(height: 8.h),
            Text('Mahsulotlarni ko\'rib chiqing va yoqqanini savatga qo\'shing',
                textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 13.5)),
            SizedBox(height: 18.h),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                appShellKey.currentState?.switchTab(0);
                Navigator.maybePop(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(14.r)),
                child: Text('Xarid qilish', style: AppTextStyles.cardTitleSm.copyWith(color: Colors.white, fontSize: 14.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends ConsumerStatefulWidget {
  const _CartItemCard({required this.item});
  final Map<String, dynamic> item;

  @override
  ConsumerState<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<_CartItemCard> {
  late int _qty;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _qty = widget.item['quantity'] as int;
  }

  Future<void> _changeQty(int delta) async {
    final next = _qty + delta;
    if (next < 1 || _busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _qty = next;
      _busy = true;
    });
    try {
      await ref.read(dioProvider).patch('/cart/${widget.item['id']}', queryParameters: {'quantity': next});
      ref.invalidate(cartProvider);
    } catch (_) {
      if (mounted) setState(() => _qty -= delta);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(dioProvider).delete('/cart/${widget.item['id']}');
      ref.invalidate(cartProvider);
    } catch (_) {
      ref.invalidate(cartProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final name = item['product_name'] as String? ?? 'Mahsulot';
    final price = double.tryParse(item['product_price']?.toString() ?? '') ?? 0;
    final imgUrl = item['product_image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final variantName = item['variant_name'] as String?;
    final lineTotal = price * _qty;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              width: 84.w,
              height: 84.w,
              color: const Color(0xFFEDE9FE),
              child: fullImg != null
                  ? Image.network(fullImg, fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(Icons.image_outlined, color: AppColors.primaryDark))
                  : Icon(Icons.inventory_2_outlined, color: AppColors.primaryDark, size: 32.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14)),
                    ),
                    GestureDetector(
                      onTap: _delete,
                      child: Icon(Icons.close, size: 15.sp, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if ((variantName ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(variantName!, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                  ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(formatSom(lineTotal), style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10.r)),
                      child: Row(
                        children: [
                          _QtyButton(icon: Icons.remove, onTap: () => _changeQty(-1)),
                          SizedBox(width: 26.w, child: Text('$_qty', textAlign: TextAlign.center, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14))),
                          _QtyButton(icon: Icons.add, onTap: () => _changeQty(1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 30.w, height: 30.w, child: Icon(icon, size: 15.sp, color: AppColors.text)),
    );
  }
}
