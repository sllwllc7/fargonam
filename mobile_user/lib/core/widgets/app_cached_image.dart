import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_shimmer.dart';

/// Tarmoqdan rasm — shimmer placeholder va xato ikonkasi bilan.
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.iconSize = 24,
  });

  final String url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surfaceAlt : AppColors.surfaceAlt;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => AppShimmer(width: width ?? double.infinity, height: height ?? double.infinity, borderRadius: 0),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: surface,
          child: Icon(Icons.image_not_supported_outlined, color: textSecondary, size: iconSize),
        ),
      ),
    );
  }
}
