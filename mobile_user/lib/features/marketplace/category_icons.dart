import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/config.dart';

/// dc.html `icon(catId)` — kategoriya slug'iga mos SVG path. Market va
/// Kategoriya-ichi ekranlari shu bitta manbadan foydalanadi.
const categoryIconPaths = <String, String>{
  'ruchka': 'M5 19l1-4L16.5 4.5a2 2 0 0 1 3 3L9 18l-4 1M14 7l3 3',
  'daftar': 'M6 3.5h12v17H6zM6 3.5v17M9.5 8h5M9.5 11.5h5',
  'qalam': 'M5 19l1.5-5L16 4.5l3.5 3.5L10 17.5 5 19M13 7.5l3.5 3.5',
  'rangli-qalam': 'M7 20V8l2.5-4L12 8v12M12 20V10l2.5-4L17 10v10',
  'a4': 'M7 3h7l4 4v14H7zM14 3v4h4',
  'rangli-qogoz': 'M5 8h10v13H5zM8 5h10v13',
  'flomaster': 'M9 3h6v7H9zM9 10l-1.5 11h9L15 10',
  'marker': 'M8 4h8v6H8zM9 10v10h6V10',
  'ochirgich': 'M5 14 12 7l6 6-7 7H7l-2-2v-4M9 10l6 6',
  'lineyka': 'M3 15 15 3l6 6L9 21zM8 12l2 2M12 8l2 2M16 4l2 2',
  'yelim': 'M10 3h4v4h-4zM8 7h8l1 4v10H7V11zM7 14h10',
  'qaychi': 'M9 9 19 19M19 5 9 15M4 7.5a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0-5 0M4 16.5a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0-5 0',
  'albom': 'M4 5h16v14H4zM7 15l3.5-4 3 3 2-2 2.5 3',
  'papka': 'M3 6h6l2 2.5h10V19H3zM3 6v13',
  'kundalik': 'M6 3h13v18H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2M9 3v18',
  'qalamdon': 'M4 10h16v9H4zM4 13h16M9 10V7h6v3',
  'shtrix': 'M9 3h6v5H9zM8 8h8v13H8zM8 14h8',
  'skotch': 'M4 12a8 8 0 1 0 16 0a8 8 0 1 0-16 0M9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0M14 20h6',
};

String categorySvg(String slug) {
  final d = categoryIconPaths[slug] ?? 'M5 5h14v14H5z';
  return '<svg viewBox="0 0 24 24"><path d="$d" stroke="#000" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';
}

/// Mahsulot rasmi — bor bo'lsa tarmoqdan (kesh bilan), bo'lmasa/xato/
/// yuklanayotganda kategoriya ikonkasi (bir xil o'lcham, joy sakramaydi).
/// Market kartasi, kategoriya ro'yxati, qidiruv, savat, sevimlilar,
/// mahsulot detali — barchasi shu bitta widget'dan foydalanadi.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.imageUrl,
    required this.categorySlug,
    required this.tint,
    this.iconSize = 52,
    this.borderRadius = 0,
    this.fallbackLabel,
  });

  final String? imageUrl;
  final String categorySlug;
  final List<Color> tint;
  final double iconSize;
  final double borderRadius;
  final Widget? fallbackLabel;

  Widget _fallback() => Container(
    color: tint[0],
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.string(
          categorySvg(categorySlug),
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(tint[1], BlendMode.srcIn),
        ),
        if (fallbackLabel != null) ...[const SizedBox(height: 7), fallbackLabel!],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final fullUrl = (url != null && url.isNotEmpty) ? '${AppConfig.apiBaseUrl}$url' : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: fullUrl == null
          ? _fallback()
          : CachedNetworkImage(
              imageUrl: fullUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => _fallback(),
              errorWidget: (context, url, error) => _fallback(),
            ),
    );
  }
}
