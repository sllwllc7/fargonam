import 'dart:ui';

import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../checkout/checkout_screen.dart';
import '../marketplace/catalog_screen.dart'
    show categoriesProvider, productCategoryMapProvider;
import '../marketplace/category_icons.dart';
import '../shell/app_shell.dart' show appShellKey;

final cartProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/cart');
  return (res.data as List).cast<Map<String, dynamic>>();
});

const _cartBagIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M5 8h14l-1.2 10.5a2 2 0 0 1-2 1.5H8.2a2 2 0 0 1-2-1.5Z" stroke="#1C1C22" stroke-width="1.7" stroke-linejoin="round" fill="none"/>'
    '<path d="M9 10V6a3 3 0 0 1 6 0v4" stroke="#1C1C22" stroke-width="1.7" stroke-linecap="round" fill="none"/></svg>';
const _trashIconSvg =
    '<svg viewBox="0 0 14 14"><path d="M2 3.5h10M5.5 3V2h3v1M3.5 3.5 4 12h6l.5-8.5" stroke="#1C1C22" stroke-width="1.4" stroke-linecap="round" fill="none"/></svg>';

/// Savat — HANDOFF.md 2-bo'lim, 6-band.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final catMapAsync = ref.watch(productCategoryMapProvider);
    final categories = categoriesAsync.value ?? const [];
    final catMap = catMapAsync.value ?? const {};

    String slugFor(int? productId) {
      final catId = productId != null ? catMap[productId] : null;
      for (final c in categories) {
        if (c.id == catId) return c.slug;
      }
      return '';
    }

    List<Color> tintFor(int? productId) {
      final catId = productId != null ? catMap[productId] : null;
      return AppColors.categoryTints[(catId ?? 0) %
          AppColors.categoryTints.length];
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ScreenFadeIn(
          child: cartAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('Yuklab bo\'lmadi', style: AppTypography.caption),
            ),
            data: (items) {
              double total = 0;
              int totalQty = 0;
              for (final ci in items) {
                final price =
                    double.tryParse(ci['product_price']?.toString() ?? '') ?? 0;
                final qty = (ci['quantity'] as int?) ?? 0;
                total += price * qty;
                totalQty += qty;
              }

              return Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            BackCircleButton(
                              onTap: () => Navigator.maybePop(context),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Savat', style: AppTypography.h2),
                                Text(
                                  totalQty > 0
                                      ? '$totalQty ta mahsulot'
                                      : 'Bo\'sh',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (items.isEmpty)
                        const Expanded(child: _EmptyCart())
                      else
                        Expanded(
                          child: RefreshIndicator(
                            color: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            onRefresh: () async {
                              HapticFeedback.lightImpact();
                              ref.invalidate(cartProvider);
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                14,
                                20,
                                20,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) => FadeUpItem(
                                delay: AppMotion.staggerStep * i,
                                child: _CartItemCard(
                                  item: items[i],
                                  iconPath: categorySvg(
                                    slugFor(items[i]['product_id'] as int?),
                                  ),
                                  tint: tintFor(items[i]['product_id'] as int?),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (items.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.94),
                              border: const Border(
                                top: BorderSide(color: Color(0x0F000000)),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Yetkazib berish',
                                      style: AppTypography.body.copyWith(
                                        height: null,
                                        color: AppColors.textMuted,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      'Bepul',
                                      style: AppTypography.rowTitle.copyWith(
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Jami',
                                      style: AppTypography.price.copyWith(
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      formatSom(total),
                                      style: AppTypography.price.copyWith(
                                        fontSize: 17,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                PressableScale(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    pushAppRoute(
                                      context,
                                      (_) => const CheckoutScreen(),
                                    );
                                  },
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.cta,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.button,
                                      ),
                                      boxShadow: AppShadows.cta,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Buyurtmani rasmiylashtirish',
                                      style: AppTypography.button,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.string(
                  _cartBagIconSvg,
                  width: 30,
                  height: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Savat bo\'sh',
              style: AppTypography.cardTitle.copyWith(
                fontSize: 17,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mahsulotlarni ko\'rib chiqing va yoqqanini savatga qo\'shing',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            PressableScale(
              scale: 0.96,
              onTap: () {
                HapticFeedback.selectionClick();
                appShellKey.currentState?.switchTab(0);
                Navigator.maybePop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Xarid qilish',
                  style: AppTypography.rowTitle.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends ConsumerStatefulWidget {
  const _CartItemCard({
    required this.item,
    required this.iconPath,
    required this.tint,
  });
  final Map<String, dynamic> item;
  final String iconPath;
  final List<Color> tint;

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
    setState(() {
      _qty = next;
      _busy = true;
    });
    try {
      await ref
          .read(dioProvider)
          .patch(
            '/cart/${widget.item['id']}',
            queryParameters: {'quantity': next},
          );
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
    final rawName = item['product_name'] as String? ?? 'Mahsulot';
    final price = double.tryParse(item['product_price']?.toString() ?? '') ?? 0;
    final variantName = item['variant_name'] as String?;
    // Backend `product_name` allaqachon "Nomi · Variant" ko'rinishida keladi
    // (/cart javobi) — variant qatorda alohida ham ko'rsatilgani uchun
    // takrorlanmasin deb shu yerda ajratib olinadi.
    final name = (variantName != null && variantName.isNotEmpty && rawName.endsWith(' · $variantName'))
        ? rawName.substring(0, rawName.length - variantName.length - 3)
        : rawName;
    final lineTotal = price * _qty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: widget.tint[0],
              borderRadius: BorderRadius.circular(AppRadius.image),
            ),
            alignment: Alignment.center,
            child: SvgPicture.string(
              widget.iconPath,
              width: 40,
              height: 40,
              colorFilter: ColorFilter.mode(widget.tint[1], BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitleSm.copyWith(height: 1.25),
                      ),
                    ),
                    GestureDetector(
                      onTap: _delete,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: SvgPicture.string(
                          _trashIconSvg,
                          width: 13,
                          height: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((variantName ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      variantName!,
                      style: AppTypography.caption.copyWith(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        formatSom(lineTotal),
                        style: AppTypography.rowTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          QtyStepperButton(
                            label: '−',
                            fontSize: 17,
                            size: 30,
                            onTap: () => _changeQty(-1),
                          ),
                          SizedBox(
                            width: 26,
                            child: Text(
                              '$_qty',
                              textAlign: TextAlign.center,
                              style: AppTypography.rowTitle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          QtyStepperButton(
                            label: '+',
                            fontSize: 16,
                            size: 30,
                            onTap: () => _changeQty(1),
                          ),
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
