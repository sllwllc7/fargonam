import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme.dart' as tokens;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cached_image.dart';
import '../../core/widgets/app_error_state.dart';
import '../cart/cart_screen.dart';
import '../favorites/favorites_screen.dart';

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

final productReviewsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, productId) async {
  final res = await ref.watch(dioProvider).get('/reviews/product/$productId');
  return res.data as Map<String, dynamic>;
});

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pAsync = ref.watch(productDetailProvider(productId));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const _CircleIconBackButton(),
        actions: [_FavoriteButton(productId: productId)],
      ),
      body: pAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(error: e, onRetry: () => ref.invalidate(productDetailProvider(productId))),
        data: (p) => _ProductBody(product: p),
      ),
    );
  }
}

class _CircleIconBackButton extends StatelessWidget {
  const _CircleIconBackButton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ProductBody extends ConsumerStatefulWidget {
  const _ProductBody({required this.product});
  final Map<String, dynamic> product;

  @override
  ConsumerState<_ProductBody> createState() => _ProductBodyState();
}

class _ProductBodyState extends ConsumerState<_ProductBody> {
  int _quantity = 1;

  List<Map<String, dynamic>> get _variants =>
      ((widget.product['variants'] as List?) ?? const []).cast<Map<String, dynamic>>();

  Future<void> _editQuantity(int maxStock) async {
    final ctrl = TextEditingController(text: '$_quantity');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
        title: const Text('Miqdorni kiriting'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          TextButton(onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)), child: const Text('OK')),
        ],
      ),
    );
    if (result != null && result >= 1) {
      setState(() => _quantity = result > maxStock ? maxStock : result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final success = isDark ? AppColorsDark.success : AppColors.success;
    final error = isDark ? AppColorsDark.error : AppColors.error;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final h1 = tokens.AppTypography.headlineLgMobile.copyWith(color: textPrimary);
    final h2 = tokens.AppTypography.headlineMd.copyWith(color: textPrimary);
    final body = isDark ? AppTextStylesDark.body : AppTextStyles.body;
    final caption = isDark ? AppTextStylesDark.caption : AppTextStyles.caption;

    final product = widget.product;
    final imgUrl = (_variants.isNotEmpty ? _variants.first['image_url'] as String? : null) ??
        product['image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;

    final hasVariants = _variants.length > 1;
    final price = num.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final stock = product['stock'] as int? ?? 0;
    final inStock = stock > 0;

    return Column(
      children: [
        // Rasm
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'product_image_${product['id']}',
                child: fullImg != null
                    ? AppCachedImage(url: fullImg, borderRadius: 0, fit: BoxFit.cover)
                    : Container(color: surface, child: Icon(Icons.image_outlined, size: 80, color: textSecondary)),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tafsilotlar
        Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.AppRadius.xl)),
          ),
          transform: Matrix4.translationValues(0, -16, 0),
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl + 4.h, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product['name'] as String, style: h1),
              if (product['shop_name'] != null) ...[
                SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.store, size: 16, color: textSecondary),
                    SizedBox(width: AppSpacing.xs),
                    Text(product['shop_name'] as String, style: caption),
                  ],
                ),
              ],
              SizedBox(height: AppSpacing.md),
              if (hasVariants)
                Text(
                  _formatPriceRange(product['min_price'], product['max_price']),
                  style: tokens.AppTypography.priceDisplay.copyWith(color: primary),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(_formatPrice(price.toString()), style: tokens.AppTypography.priceDisplay.copyWith(color: primary)),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: (inStock ? success : error).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Text(
                        inStock ? (stock <= 5 ? 'Faqat $stock ta qoldi' : 'Bor: $stock dona') : 'Tugagan',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: inStock ? success : error),
                      ),
                    ),
                  ],
                ),

              // Turlari ro'yxati — har biri o'z rasmi, narxi va tezkor
              // qo'shish tugmalari (+1/+5/+10) bilan, alohida tanlashsiz
              if (hasVariants) ...[
                SizedBox(height: AppSpacing.xl),
                Text('Turlari', style: h2),
                SizedBox(height: AppSpacing.md),
                for (final v in _variants) ...[
                  _VariantRow(productImageUrl: product['image_url'] as String?, variant: v),
                  SizedBox(height: AppSpacing.md),
                ],
              ],

              // Miqdor tanlash — faqat yagona (standart) turli mahsulotda
              if (!hasVariants && inStock) ...[
                SizedBox(height: AppSpacing.xl),
                Text('Miqdor', style: h2),
                SizedBox(height: AppSpacing.md),
                _QuantityStepper(
                  quantity: _quantity,
                  maxStock: stock,
                  onChanged: (q) => setState(() => _quantity = q),
                  onTapNumber: () => _editQuantity(stock),
                ),
              ],

              if (product['description'] != null && (product['description'] as String).isNotEmpty) ...[
                SizedBox(height: AppSpacing.xl),
                Divider(color: isDark ? AppColorsDark.border : AppColors.border),
                SizedBox(height: AppSpacing.md),
                Text('Tavsif', style: h2),
                SizedBox(height: AppSpacing.sm),
                Text(product['description'] as String, style: body.copyWith(color: textSecondary, height: 1.5)),
              ],
              SizedBox(height: AppSpacing.lg),

              _ReviewsSection(productId: product['id'] as int),
              SizedBox(height: AppSpacing.xl),

              if (!hasVariants)
                SizedBox(
                  width: double.infinity,
                  child: _AddToCartButton(
                    productId: product['id'] as int,
                    variantId: null,
                    quantity: _quantity,
                    inStock: inStock,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Variant qatori — rasm chapda, ma'lumot va tezkor qo'shish o'ngda ──

class _VariantRow extends ConsumerStatefulWidget {
  const _VariantRow({required this.productImageUrl, required this.variant});
  final String? productImageUrl;
  final Map<String, dynamic> variant;

  @override
  ConsumerState<_VariantRow> createState() => _VariantRowState();
}

class _VariantRowState extends ConsumerState<_VariantRow> {
  bool _adding = false;

  Future<void> _add(int qty) async {
    if (_adding) return;
    HapticFeedback.mediumImpact();
    setState(() => _adding = true);
    try {
      await ref.read(dioProvider).post('/cart', data: {
        'variant_id': widget.variant['id'] as int,
        'quantity': qty,
      });
      ref.invalidate(cartProvider);
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: isDark ? AppColorsDark.error : AppColors.error,
            duration: const Duration(milliseconds: 1600),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final success = isDark ? AppColorsDark.success : AppColors.success;
    final error = isDark ? AppColorsDark.error : AppColors.error;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final v = widget.variant;
    final variantId = v['id'] as int;
    final stock = v['stock'] as int? ?? 0;
    final inStock = stock > 0;

    final cartAsync = ref.watch(cartProvider);
    final cartQty = cartAsync.maybeWhen(
      data: (items) {
        for (final it in items) {
          if (it['variant_id'] == variantId) return it['quantity'] as int? ?? 0;
        }
        return 0;
      },
      orElse: () => 0,
    );
    final remaining = stock - cartQty;

    final imgUrl = (v['image_url'] as String?) ?? widget.productImageUrl;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(tokens.AppRadius.xl)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.AppRadius.lg),
            child: SizedBox(
              width: 64.w,
              height: 64.w,
              child: fullImg != null
                  ? AppCachedImage(url: fullImg, borderRadius: 0, fit: BoxFit.cover)
                  : Container(color: background, child: Icon(Icons.image_outlined, color: textSecondary)),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v['variant_name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ),
                    if (cartQty > 0) ...[
                      SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text('Savatda: $cartQty',
                            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: success)),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  _formatPrice((v['price'] as num?)?.toString() ?? '0'),
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: primary),
                ),
                SizedBox(height: 4.h),
                Text(
                  inStock ? (stock <= 5 ? 'Faqat $stock ta qoldi' : 'Bor: $stock dona') : 'Tugagan',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: inStock ? textSecondary : error),
                ),
                SizedBox(height: AppSpacing.sm),
                if (inStock)
                  Row(
                    children: [
                      for (final n in [1, 5, 10]) ...[
                        _QuickAddChip(
                          label: '+$n',
                          enabled: !_adding && remaining >= n,
                          onTap: () => _add(n),
                        ),
                        if (n != 10) SizedBox(width: AppSpacing.xs),
                      ],
                      if (_adding) ...[
                        SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                        ),
                      ],
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

class _QuickAddChip extends StatelessWidget {
  const _QuickAddChip({required this.label, required this.enabled, required this.onTap});
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.chip)),
          child: Text(
            label,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: enabled ? primary : textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── Miqdor stepper — kichik o'zgarish uchun +/-, katta sakrash uchun
// raqamga bosib to'g'ridan-to'g'ri kiritish (NN/g va Baymard tavsiyasiga
// ko'ra, +5/+10 tez tugmalar emas — bu tadqiqot bilan tasdiqlangan) ──

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.maxStock,
    required this.onChanged,
    required this.onTapNumber,
  });
  final int quantity;
  final int maxStock;
  final ValueChanged<int> onChanged;
  final VoidCallback onTapNumber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            enabled: quantity > 1,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(quantity - 1);
            },
          ),
          GestureDetector(
            onTap: onTapNumber,
            child: Container(
              constraints: BoxConstraints(minWidth: 44.w),
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              alignment: Alignment.center,
              child: Text('$quantity', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, color: textPrimary)),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: quantity < maxStock,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(quantity + 1);
            },
          ),
          SizedBox(width: AppSpacing.sm),
          Text('/ $maxStock ta', style: TextStyle(fontSize: 12.sp, color: textSecondary)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: enabled ? primary : textSecondary.withValues(alpha: 0.4)),
      ),
    );
  }
}

// ── Savatga qo'shish tugmasi ─────────────────────────────────

class _AddToCartButton extends ConsumerStatefulWidget {
  const _AddToCartButton({
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.inStock,
  });
  final int productId;
  final int? variantId;
  final int quantity;
  final bool inStock;
  @override
  ConsumerState<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends ConsumerState<_AddToCartButton> {
  bool _loading = false;
  bool _added = false;

  Future<void> _add() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{'quantity': widget.quantity};
      if (widget.variantId != null) {
        data['variant_id'] = widget.variantId;
      } else {
        data['product_id'] = widget.productId;
      }
      await ref.read(dioProvider).post('/cart', data: data);
      ref.invalidate(cartProvider);
      setState(() => _added = true);
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _showCartSnackBar(
          context,
          text: 'Savatchaga qo\'shildi',
          color: isDark ? AppColorsDark.success : AppColors.success,
        );
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _showCartSnackBar(
          context,
          text: e.response?.data['detail']?.toString() ?? 'Xato',
          color: isDark ? AppColorsDark.error : AppColors.error,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inStock) {
      return const AppButton(label: 'Mahsulot tugagan', onPressed: null);
    }
    if (_added) {
      return AppButton(label: 'Savatchada', icon: Icons.check_circle, onPressed: null);
    }
    return AppButton(
      label: 'Savatchaga qo\'shish',
      icon: Icons.add_shopping_cart,
      loading: _loading,
      onPressed: _add,
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavAsync = ref.watch(isFavoriteProvider(productId));
    return isFavAsync.when(
      loading: () => SizedBox(width: 48.w),
      error: (_, _) => SizedBox(width: 48.w),
      data: (isFav) => Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            final dio = ref.read(dioProvider);
            if (isFav) {
              await dio.delete('/favorites/$productId');
            } else {
              await dio.post('/favorites/$productId');
            }
            ref.invalidate(isFavoriteProvider(productId));
            ref.invalidate(favoritesProvider);
          },
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Narxni chiroyli formatlash: 1250000 -> 1 250 000 so'm
String _formatPrice(String raw) {
  final num = double.tryParse(raw);
  if (num == null) return '$raw so\'m';
  final intStr = num.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf so\'m';
}

/// Bir nechta turi bo'lgan mahsulot uchun narx oralig'i: "5 000 - 12 000 so'm"
String _formatPriceRange(dynamic min, dynamic max) {
  final minStr = min?.toString();
  final maxStr = max?.toString();
  if (minStr == null) return _formatPrice('0');
  if (maxStr == null || minStr == maxStr) return _formatPrice(minStr);
  final minNum = double.tryParse(minStr);
  final maxNum = double.tryParse(maxStr);
  if (minNum == maxNum) return _formatPrice(minStr);
  final formattedMin = _formatPrice(minStr).replaceAll(' so\'m', '');
  return '$formattedMin - ${_formatPrice(maxStr)}';
}

class _ReviewsSection extends ConsumerStatefulWidget {
  const _ReviewsSection({required this.productId});
  final int productId;
  @override
  ConsumerState<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<_ReviewsSection> {
  int _myRating = 0;
  final _commentCtrl = TextEditingController();
  bool _showForm = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_myRating == 0) return;
    await ref.read(dioProvider).post('/reviews/product/${widget.productId}', data: {
      'rating': _myRating,
      if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
    });
    _commentCtrl.clear();
    setState(() {
      _showForm = false;
      _myRating = 0;
    });
    ref.invalidate(productReviewsProvider(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final rating = isDark ? AppColorsDark.rating : AppColors.rating;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final h2 = isDark ? AppTextStylesDark.h2 : AppTextStyles.h2;
    final caption = isDark ? AppTextStylesDark.caption : AppTextStyles.caption;

    final reviewsAsync = ref.watch(productReviewsProvider(widget.productId));
    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final avg = data['avg_rating'];
        final total = data['total'] as int;
        final items = (data['items'] as List).cast<Map<String, dynamic>>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: isDark ? AppColorsDark.border : AppColors.border),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('Sharhlar', style: h2),
                SizedBox(width: AppSpacing.sm),
                if (avg != null) ...[
                  Icon(Icons.star, color: rating, size: 18),
                  Text(' $avg', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  Text(' ($total)', style: caption),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _showForm = !_showForm),
                  child: Text(_showForm ? 'Yopish' : 'Sharh qo\'shish', style: TextStyle(color: primary)),
                ),
              ],
            ),
            if (_showForm) ...[
              SizedBox(height: AppSpacing.sm),
              Row(
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _myRating = i + 1),
                    child: Icon(i < _myRating ? Icons.star : Icons.star_border, color: rating, size: 32),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _commentCtrl,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Fikringiz (ixtiyoriy)...',
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide.none),
                ),
                maxLines: 2,
              ),
              SizedBox(height: AppSpacing.sm),
              AppButton(label: 'Yuborish', fullWidth: false, onPressed: _myRating > 0 ? _submitReview : null),
            ],
            for (final r in items.take(3)) ...[
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(i < (r['rating'] as int) ? Icons.star : Icons.star_border, color: rating, size: 16),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(r['user_name'] as String, style: caption),
                ],
              ),
              if (r['comment'] != null && (r['comment'] as String).isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(r['comment'] as String, style: TextStyle(fontSize: 13.sp, color: textPrimary)),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// Savatga qo'shish snackbar'i — floating, navbatga to'planmaydi
/// (bu ekranda pastki navigatsiya yo'q, shuning uchun margin kichikroq).
void _showCartSnackBar(BuildContext context, {required String text, required Color color}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 2),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
    ),
  );
}
