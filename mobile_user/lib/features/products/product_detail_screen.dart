import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../cart/cart_screen.dart' show cartProvider;
import '../favorites/favorites_screen.dart' show favoritesProvider;
import '../marketplace/catalog_screen.dart' show categoriesProvider;
import '../marketplace/category_icons.dart';

final productDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  id,
) async {
  final res = await ref.watch(dioProvider).get('/products/$id');
  return res.data as Map<String, dynamic>;
});

final isFavoriteProvider = FutureProvider.family<bool, int>((
  ref,
  productId,
) async {
  try {
    final res = await ref.watch(dioProvider).get('/favorites/check/$productId');
    return res.data['is_favorite'] as bool;
  } catch (_) {
    return false;
  }
});

/// dc.html `stockInfo()` — zaxira holatiga qarab yorliq+rang.
(String, Color) _stockInfo(int stock) {
  if (stock == 0) return ('Tugagan', AppColors.danger);
  if (stock < 10) return ('Kam qolgan · $stock dona', AppColors.primary);
  return ('Mavjud', AppColors.textPrimary);
}

/// Dot indikator faol bo'lmagan holati — dc.html `pdDots` `#C2CCDB`.
const _dotInactiveColor = Color(0xFFC2CCDB);

/// Mahsulot sahifasi — HANDOFF.md 2-bo'lim, 5-band.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final Map<String, String> _selected = {};
  int _qty = 1;
  bool _adding = false;
  bool _initialized = false;

  void _initSelection(Map<String, dynamic> product) {
    if (_initialized) return;
    _initialized = true;
    final variants = (product['variants'] as List? ?? [])
        .cast<Map<String, dynamic>>();
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
      final matches = _selected.entries.every(
        (e) => attrs[e.key]?.toString() == e.value,
      );
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
      await ref
          .read(dioProvider)
          .post('/cart', data: {'variant_id': variant['id'], 'quantity': _qty});
      ref.invalidate(cartProvider);
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Savatga qo\'shildi'),
            backgroundColor: AppColors.success,
          ),
        );
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
    final pAsync = ref.watch(productDetailProvider(widget.productId));
    final favAsync = ref.watch(isFavoriteProvider(widget.productId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Yuklab bo\'lmadi', style: AppTypography.caption),
        ),
        data: (p) {
          _initSelection(p);
          final variants = (p['variants'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          final variant = _findVariant(variants);
          final attrNames = _attrNames(variants);
          final stock = variant?['stock'] as int? ?? 0;
          final price = (variant?['price'] as num?)?.toInt() ?? 0;
          final isFav = favAsync.value ?? false;
          final canAdd = variant != null && stock > 0;
          final (stockLabel, stockColor) = _stockInfo(stock);
          final name = p['name'] as String? ?? '';

          final categoryId = p['category_id'] as int?;
          final categories = categoriesAsync.value ?? const [];
          var slug = '';
          for (final c in categories) {
            if (c.id == categoryId) {
              slug = c.slug;
              break;
            }
          }
          final tint =
              AppColors.categoryTints[(categoryId ?? 0) %
                  AppColors.categoryTints.length];

          return SafeArea(
            bottom: false,
            child: ScreenFadeIn(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.only(bottom: 132),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BackCircleButton(
                              onTap: () => Navigator.maybePop(context),
                            ),
                            _RoundFavButton(
                              active: isFav,
                              onTap: () => _toggleFav(widget.productId, isFav),
                            ),
                          ],
                        ),
                      ),
                      _ProductImageCarousel(
                        iconPath: categorySvg(slug),
                        bg: tint[0],
                        fg: tint[1],
                        labels: [
                          '${name.toLowerCase()} — asosiy rasm',
                          'yon tomondan',
                          'yaqindan',
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((p['brand'] as String? ?? '').isNotEmpty)
                              Text(
                                (p['brand'] as String).toUpperCase(),
                                style: AppTypography.eyebrow.copyWith(
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 22,
                                letterSpacing: -0.4,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  formatSom(price),
                                  style: AppTypography.price,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  stockLabel,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 12.5,
                                    height: null,
                                    color: stockColor,
                                  ),
                                ),
                              ],
                            ),
                            if ((p['description'] as String? ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                p['description'] as String,
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      for (final attrName in attrNames)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attrName,
                                style: AppTypography.rowTitle.copyWith(
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final val in _valuesFor(
                                    variants,
                                    attrName,
                                  ))
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
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Miqdor', style: AppTypography.rowTitle),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.input,
                                ),
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppShadows.card,
                              ),
                              child: Row(
                                children: [
                                  QtyStepperButton(
                                    label: '−',
                                    fontSize: 20,
                                    onTap: () => setState(
                                      () => _qty = _qty > 1 ? _qty - 1 : 1,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 34,
                                    child: Text(
                                      '$_qty',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.rowTitle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  QtyStepperButton(
                                    label: '+',
                                    fontSize: 19,
                                    onTap: () => setState(
                                      () =>
                                          _qty = _qty < stock ? _qty + 1 : _qty,
                                    ),
                                  ),
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
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0, 0.7, 1],
                          colors: [
                            AppColors.background,
                            AppColors.background,
                            AppColors.background.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jami',
                                style: AppTypography.small.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                formatSom(price * _qty),
                                style: AppTypography.price.copyWith(
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PressableScale(
                              onTap: (!canAdd || _adding)
                                  ? () {}
                                  : () => _addToCart(variant),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: canAdd
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.button,
                                  ),
                                  boxShadow: AppShadows.cta,
                                ),
                                alignment: Alignment.center,
                                child: _adding
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        canAdd
                                            ? 'Savatga qo\'shish'
                                            : 'Tugagan',
                                        style: AppTypography.button,
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
            ),
          );
        },
      ),
    );
  }

  List<String> _valuesFor(
    List<Map<String, dynamic>> variants,
    String attrName,
  ) {
    final values = <String>[];
    for (final v in variants) {
      final attrs = v['attributes'] as Map? ?? {};
      final val = attrs[attrName]?.toString();
      if (val != null && !values.contains(val)) values.add(val);
    }
    return values;
  }
}

class _RoundFavButton extends StatelessWidget {
  const _RoundFavButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.92,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.border,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FavoriteHeartIcon(active: active, size: 17),
      ),
    );
  }
}

/// dc.html'dagi 3D "coverflow" rasm karuseli (`pdSlides`) soddalashtirilgan
/// ko'rinishda — aniq CSS perspective/rotateY o'rniga scale+qorayish bilan
/// taqlid qilinadi (dekorativ effekt, biznes-mantiqqa taalluqli emas).
/// Bosilganda keyingi rasmga o'tadi, nuqta bosilganda o'sha rasmga sakraydi.
class _ProductImageCarousel extends StatefulWidget {
  const _ProductImageCarousel({
    required this.iconPath,
    required this.bg,
    required this.fg,
    required this.labels,
  });
  final String iconPath;
  final Color bg;
  final Color fg;
  final List<String> labels;

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  int _index = 0;

  void _goTo(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.labels.length;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _goTo((_index + 1) % n),
          child: SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [for (var i = 0; i < n; i++) _buildSlide(i, n)],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++)
              GestureDetector(
                onTap: () => _goTo(i),
                child: AnimatedContainer(
                  duration: AppMotion.fadeUp,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: i == _index ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.textPrimary
                        : _dotInactiveColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlide(int i, int n) {
    var d = i - _index;
    d = ((d % n) + n) % n;
    if (d > n ~/ 2) d -= n;
    if (d < 0) return const SizedBox.shrink();
    final forward = d.clamp(0, 1).toDouble();

    return AnimatedContainer(
      duration: AppMotion.screenIn,
      curve: AppMotion.standard,
      transformAlignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(forward * 26, 0, 0, 1)
        ..scaleByDouble(1 - forward * 0.08, 1 - forward * 0.08, 1, 1),
      width: MediaQuery.of(context).size.width * 0.78,
      height: 270,
      decoration: BoxDecoration(
        color: Color.lerp(widget.bg, Colors.black, forward * 0.18),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: d == 0 ? AppShadows.productImage : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.string(
            widget.iconPath,
            width: 96,
            height: 96,
            colorFilter: ColorFilter.mode(widget.fg, BlendMode.srcIn),
          ),
          const SizedBox(height: 12),
          Text(
            widget.labels[i],
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: widget.fg.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttrChip extends StatelessWidget {
  const _AttrChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.94,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.borderStrong,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.cardTitleSm.copyWith(
            fontSize: 14,
            letterSpacing: 0,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
