import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../cart/cart_screen.dart' show CartScreen, cartProvider;
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

/// Mahsulotning qo'shimcha galereya rasmlari — asosiy `image_url`dan
/// tashqari, `/products/{id}/images` orqali (sotuvchi qo'shgan bo'lsa).
final productGalleryProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((
  ref,
  id,
) async {
  try {
    final res = await ref.watch(dioProvider).get('/products/$id/images');
    return (res.data as List).cast<Map<String, dynamic>>();
  } catch (_) {
    return const [];
  }
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
        showAppToast(
          context,
          'Savatga qo\'shildi',
          onCartTap: () => pushAppRoute(context, (_) => const CartScreen()),
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
    final galleryAsync = ref.watch(productGalleryProvider(widget.productId));

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

          // Barcha rasmlar: asosiy (image_url) + galereya, dublikat
          // URL'lar bitta marta (sotuvchi galereyadagi rasmni "Asosiy"
          // qilganda ikkalasi bir xil bo'lib qolishi mumkin).
          final mainImg = p['image_url'] as String?;
          final gallery = galleryAsync.value ?? const [];
          final seenUrls = <String>{};
          final imageUrls = <String>[
            if (mainImg != null && mainImg.isNotEmpty) mainImg,
            for (final g in gallery)
              if (g['image_url'] != null) g['image_url'] as String,
          ].where((u) => seenUrls.add(u)).toList();

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
                        imageUrls: imageUrls,
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

/// dc.html'dagi 3D "coverflow" rasm karuseli (`pdSlides`, dc.html:1127-1139)
/// aynan: `Matrix4..setEntry(3,2,1/1200)` orqali perspective (CSS
/// `perspective:1200px`ga mos), rotateY, translateX/Z, brightness (rangni
/// qora tomon lerp qilish — `filter:brightness()` bilan matematik teng),
/// blur (`ImageFiltered`). Bosilganda keyingi rasmga o'tadi, nuqta
/// bosilganda o'sha rasmga sakraydi.
class _ProductImageCarousel extends StatefulWidget {
  const _ProductImageCarousel({
    required this.imageUrls,
    required this.iconPath,
    required this.bg,
    required this.fg,
    required this.labels,
  });
  // Haqiqiy rasm(lar) — bor bo'lsa shular ko'rsatiladi (to'liq URL, allaqachon
  // apiBaseUrl bilan). Bo'sh bo'lsa `labels` soniga mos, ikonka+matn bilan
  // eski placeholder ko'rinishi (hozirgi ikonka) saqlanadi.
  final List<String> imageUrls;
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

  /// dc.html: `d = i - cimg`, `n`ga nisbatan aylana masofasi (`-1..1`, n=3'da).
  int _circularDelta(int i, int n) {
    var d = i - _index;
    d = ((d % n) + n) % n;
    if (d > n ~/ 2) d -= n;
    return d;
  }

  bool get _hasImages => widget.imageUrls.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final n = _hasImages ? widget.imageUrls.length : widget.labels.length;
    // dc.html `z: 100 - round(d*10)` — z kichikroq (d kattaroq) avval
    // chizilishi kerak (Stack'da keyingi bola tepada chiqadi).
    final order = List<int>.generate(n, (i) => i)
      ..sort((a, b) => _circularDelta(b, n).compareTo(_circularDelta(a, n)));

    return Column(
      children: [
        GestureDetector(
          onTap: () => _goTo((_index + 1) % n),
          child: SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (final i in order) _buildSlide(i, _circularDelta(i, n)),
              ],
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

  /// Rasm yo'q/xato/yuklanayotgan holatda — ikonka (haqiqiy rasm rejimida
  /// matnsiz, faqat CachedNetworkImage placeholder/errorWidget sifatida).
  Widget _iconFallback(int i) {
    return Container(
      color: widget.bg,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(
            widget.iconPath,
            width: 96,
            height: 96,
            colorFilter: ColorFilter.mode(widget.fg, BlendMode.srcIn),
          ),
          if (!_hasImages) ...[
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
        ],
      ),
    );
  }

  /// dc.html `pdSlides` formulasi aynan (1127-1139-qatorlar):
  /// `tf: translate(-50%,-50%) translateX(d*40) translateZ(-d*130) rotateY(clamp(d,0,1)*16deg)`,
  /// `op: d<0 ? max(0,1+d) : 1`, `filter: brightness(max(.55,1-back*.18)) blur(back*1.5px)`.
  Widget _buildSlide(int i, int d) {
    final dd = d.toDouble();
    final back = dd < 0 ? 0.0 : dd;
    final rotateDeg = dd.clamp(0.0, 1.0) * 16.0;
    final opacity = dd < 0 ? (1 + dd).clamp(0.0, 1.0) : 1.0;
    // filter:brightness(x) — har bir rang kanalini x ga ko'paytiradi, bu
    // rangni qora tomon (1-x) ulushda lerp qilish bilan matematik teng.
    final brightness = (1 - back * 0.18).clamp(0.55, 1.0);
    final blurPx = back * 1.5;
    final dx = dd * 40.0;
    final dz = -dd * 130.0;

    final matrix = Matrix4.identity()
      // CSS `perspective:1200px` — Flutter'da vector_math m[3][2] orqali taqlid.
      ..setEntry(3, 2, 1 / 1200)
      ..translateByDouble(dx, 0.0, dz, 1)
      ..rotateY(rotateDeg * math.pi / 180);

    final slideContent = _hasImages
        ? ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: '${AppConfig.apiBaseUrl}${widget.imageUrls[i]}',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _iconFallback(i),
                  errorWidget: (context, url, error) => _iconFallback(i),
                ),
                // dc.html'dagi `filter:brightness()` — orqadagi qatlamlar
                // xiralashsin, rasmning o'zi CSS filter emas (Flutter'da
                // rasm ustiga qora overlay bilan aynan shu effekt beriladi).
                if (back > 0) Container(color: Colors.black.withValues(alpha: 1 - brightness)),
              ],
            ),
          )
        : _iconFallback(i);

    Widget slide = AnimatedContainer(
      duration: AppMotion.screenIn,
      curve: AppMotion.standard,
      transformAlignment: Alignment.center,
      transform: matrix,
      width: MediaQuery.of(context).size.width * 0.78,
      height: 270,
      decoration: BoxDecoration(
        color: _hasImages ? null : Color.lerp(widget.bg, Colors.black, 1 - brightness),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.productImage,
      ),
      child: slideContent,
    );

    return AnimatedOpacity(
      key: ValueKey('slide_$i'),
      duration: AppMotion.screenIn,
      curve: AppMotion.standard,
      opacity: opacity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: blurPx, end: blurPx),
        duration: AppMotion.screenIn,
        curve: AppMotion.standard,
        builder: (context, animatedBlur, child) {
          if (animatedBlur <= 0) return child!;
          return ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: animatedBlur,
              sigmaY: animatedBlur,
            ),
            child: child,
          );
        },
        child: slide,
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
