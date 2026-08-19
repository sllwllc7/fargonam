import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../cart/cart_screen.dart' show cartProvider;
import 'kit_providers.dart';

/// Sinf to'plami — HANDOFF.md 2-bo'lim, 3-band.
class KitDetailScreen extends ConsumerStatefulWidget {
  const KitDetailScreen({super.key, required this.kit});
  final Kit kit;

  @override
  ConsumerState<KitDetailScreen> createState() => _KitDetailScreenState();
}

class _KitDetailScreenState extends ConsumerState<KitDetailScreen> {
  bool _adding = false;

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf soʻm';
  }

  Future<void> _addKit() async {
    HapticFeedback.mediumImpact();
    setState(() => _adding = true);
    try {
      final dio = ref.read(dioProvider);
      for (final item in widget.kit.items) {
        await dio.post('/cart', data: {'variant_id': item.variantId, 'quantity': item.quantity});
      }
      ref.invalidate(cartProvider);
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('To\'plam savatga qo\'shildi'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kit;
    final tint = AppColors.categoryTints[(int.tryParse(k.gradeLevel ?? '1') ?? 1) % AppColors.categoryTints.length];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(bottom: 120.h),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.pop(context)),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(k.name, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${k.items.length} xil mahsulot · to\'liq komplekt', style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(color: tint[0], borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
                  child: Row(
                    children: [
                      Container(
                        width: 52.w,
                        height: 52.w,
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15.r)),
                        child: Center(
                          child: Text(k.gradeLevel ?? '?', style: AppTextStyles.h2.copyWith(color: tint[1], fontSize: 22)),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          'Do\'kon tomonidan tayyorlangan — hammasi bitta to\'plamda, alohida qidirish shart emas',
                          style: AppTextStyles.bodyMedium.copyWith(color: tint[1], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      for (final it in k.items)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0D000000)))),
                          child: Row(
                            children: [
                              Container(
                                width: 52.w,
                                height: 52.w,
                                decoration: BoxDecoration(color: tint[0], borderRadius: BorderRadius.circular(14.r)),
                                child: Icon(Icons.inventory_2_outlined, color: tint[1], size: 24.sp),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(it.productName ?? 'Mahsulot', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14)),
                                    if ((it.variantName ?? '').isNotEmpty)
                                      Text(it.variantName!, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('× ${it.quantity}', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5)),
                                  Text(_fmt(it.lineTotal ?? 0), style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Jami', style: AppTextStyles.cardTitle.copyWith(fontSize: 15.5)),
                            Text(_fmt(k.total), style: AppTextStyles.cardTitle.copyWith(fontSize: 15.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 30.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0, 0.7, 1],
                    colors: [AppColors.bg, AppColors.bg, AppColors.bg.withValues(alpha: 0)],
                  ),
                ),
                child: GestureDetector(
                  onTap: _adding ? null : _addKit,
                  child: Container(
                    height: 54.h,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(17.r),
                      boxShadow: AppShadows.primaryButton,
                    ),
                    child: Center(
                      child: _adding
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text('To\'plamni savatga qo\'shish · ${_fmt(k.total)}',
                              style: AppTextStyles.button, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(Icons.arrow_back_ios_new, size: 15.sp, color: AppColors.text),
      ),
    );
  }
}
