import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../cart/cart_screen.dart' show cartProvider;
import '../favorites/favorites_screen.dart' show favoritesProvider;

final productDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final res = await ref.watch(dioProvider).get('/products/$id');
  return res.data as Map<String, dynamic>;
});

final isFavoriteProvider = FutureProvider.family<bool, int>((ref, productId) async {
  try {
    final res = await ref.watch(dioProvider).get('/favorites/check/$productId');
    return res.data['is_favorite'] as bool;
  } catch (_) {
    return false;
  }
});

String _fmt(num n) {
  final s = n.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf so\'m';
}

/// Mahsulot sahifasi — HANDOFF.md 2-bo'lim, 5-band.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final Map<String, String> _selected = {};
  int _qty = 1;
  bool _adding = false;
  bool _initialized = false;

  void _initSelection(Map<String, dynamic> product) {
    if (_initialized) return;
    _initialized = true;
    final variants = (product['variants'] as List? ?? []).cast<Map<String, dynamic>>();
    if (variants.isEmpty) return;
    final attrs = _attrNames(variants);
    final first = variants.first['attributes'] as Map? ?? {};
    for (final name in attrs) {
      if (first[name] != null) _selected[name] = first[name].toString();
    }
  }

  List<String> _attrNames(List<Map<String, dynamic>> variants) {
    final names = <String>[];
    for (final v in variants) {
      final attrs = v['attributes'] as Map? ?? {};
      for (final k in attrs.keys) {
        if (!names.contains(k)) names.add(k.toString());
      }
    }
    return names;
  }

  Map<String, dynamic>? _findVariant(List<Map<String, dynamic>> variants) {
    if (variants.length == 1) return variants.first;
    for (final v in variants) {
      final attrs = v['attributes'] as Map? ?? {};
      final matches = _selected.entries.every((e) => attrs[e.key]?.toString() == e.value);
      if (matches) return v;
    }
    return variants.isNotEmpty ? variants.first : null;
  }

  Future<void> _toggleFav(int productId, bool isFav) async {
    HapticFeedback.selectionClick();
    final dio = ref.read(dioProvider);
    if (isFav) {
      await dio.delete('/favorites/$productId');
    } else {
      await dio.post('/favorites/$productId');
    }
    ref.invalidate(isFavoriteProvider(productId));
    ref.invalidate(favoritesProvider);
  }

  Future<void> _addToCart(Map<String, dynamic> variant) async {
    HapticFeedback.mediumImpact();
    setState(() => _adding = true);
    try {
      await ref.read(dioProvider).post('/cart', data: {'variant_id': variant['id'], 'quantity': _qty});
      ref.invalidate(cartProvider);
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Savatga qo\'shildi'), backgroundColor: AppColors.success),
        );
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['detail']?.toString() ?? 'Xato'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pAsync = ref.watch(productDetailProvider(widget.productId));
    final favAsync = ref.watch(isFavoriteProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: pAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Yuklab bo\'lmadi', style: AppTextStyles.caption)),
        data: (p) {
          _initSelection(p);
          final variants = (p['variants'] as List? ?? []).cast<Map<String, dynamic>>();
          final variant = _findVariant(variants);
          final attrNames = _attrNames(variants);
          final stock = variant?['stock'] as int? ?? 0;
          final price = (variant?['price'] as num?)?.toInt() ?? 0;
          final isFav = favAsync.value ?? false;
          final canAdd = variant != null && stock > 0;

          return SafeArea(
            bottom: false,
            child: Stack(
              children: [
                ListView(
                  padding: EdgeInsets.only(bottom: 130.h),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RoundButton(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.maybePop(context)),
                          _RoundButton(
                            icon: isFav ? Icons.favorite : Icons.favorite_border,
                            iconColor: isFav ? AppColors.danger : AppColors.text,
                            onTap: () => _toggleFav(widget.productId, isFav),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                      decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(20.r)),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Center(child: Icon(Icons.inventory_2_outlined, size: 100.sp, color: AppColors.primaryDark)),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 16.w, height: 5, margin: EdgeInsets.symmetric(horizontal: 2.w), decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(3))),
                          Container(width: 5, height: 5, margin: EdgeInsets.symmetric(horizontal: 2.w), decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle)),
                          Container(width: 5, height: 5, margin: EdgeInsets.symmetric(horizontal: 2.w), decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((p['brand'] as String? ?? '').isNotEmpty)
                            Text((p['brand'] as String).toUpperCase(), style: AppTextStyles.small.copyWith(color: AppColors.text, fontSize: 12, letterSpacing: 0.5)),
                          SizedBox(height: 4.h),
                          Text(p['name'] as String? ?? '', style: AppTextStyles.h2.copyWith(fontSize: 22)),
                          SizedBox(height: 8.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(_fmt(price), style: AppTextStyles.h2.copyWith(fontSize: 24)),
                              SizedBox(width: 10.w),
                              Text(
                                stock == 0 ? 'Tugagan' : (stock < 10 ? 'Kam qolgan · $stock dona' : 'Mavjud'),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 12.5,
                                  color: stock == 0 ? AppColors.textMuted : AppColors.text,
                                ),
                              ),
                            ],
                          ),
                          if ((p['description'] as String? ?? '').isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            Text(p['description'] as String, style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 14, height: 1.5)),
                          ],
                        ],
                      ),
                    ),
                    for (final attrName in attrNames)
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(attrName, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14.5)),
                            SizedBox(height: 10.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: [
                                for (final val in _valuesFor(variants, attrName))
                                  _AttrChip(
                                    label: val,
                                    selected: _selected[attrName] == val,
                                    onTap: () => setState(() {
                                      _selected[attrName] = val;
                                      _qty = 1;
                                    }),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Miqdor', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14.5)),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                _StepperButton(icon: Icons.remove, onTap: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1)),
                                SizedBox(width: 34.w, child: Text('$_qty', textAlign: TextAlign.center, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 16))),
                                _StepperButton(icon: Icons.add, onTap: () => setState(() => _qty = _qty < stock ? _qty + 1 : _qty)),
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
                    color: AppColors.bg,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jami', style: AppTextStyles.small.copyWith(fontSize: 11)),
                            Text(_fmt(price * _qty), style: AppTextStyles.h2.copyWith(fontSize: 18)),
                          ],
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: (!canAdd || _adding) ? null : () => _addToCart(variant),
                            child: Container(
                              height: 52.h,
                              decoration: BoxDecoration(
                                gradient: canAdd ? AppGradients.primary : null,
                                color: canAdd ? null : AppColors.textMuted,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Center(
                                child: _adding
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : Text(canAdd ? 'Savatga qo\'shish' : 'Tugagan', style: AppTextStyles.button),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _valuesFor(List<Map<String, dynamic>> variants, String attrName) {
    final values = <String>[];
    for (final v in variants) {
      final attrs = v['attributes'] as Map? ?? {};
      final val = attrs[attrName]?.toString();
      if (val != null && !values.contains(val)) values.add(val);
    }
    return values;
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.iconColor});
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

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
        decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
        child: Icon(icon, size: 16.sp, color: iconColor ?? AppColors.text),
      ),
    );
  }
}

class _AttrChip extends StatelessWidget {
  const _AttrChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.text : AppColors.surface,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: selected ? AppColors.text : AppColors.borderStrong, width: 1.5),
        ),
        child: Text(label, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14, color: selected ? Colors.white : AppColors.text)),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(width: 40.w, height: 40.w, child: Icon(icon, size: 18.sp, color: AppColors.text)),
    );
  }
}
