import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Kutuku kartochka — soya YO'Q, chegara YO'Q (`design/TOKENS.md`: "kartochkada
/// chegara yo'q — rasm foni ajratadi"). Ajratish fon rangi va bo'sh joy bilan.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? AppColorsDark.surface : AppColors.background);
    final radius = BorderRadius.circular(AppRadius.card);

    final content = Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}
