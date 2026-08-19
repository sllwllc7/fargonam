import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppBadgeVariant { primary, success, error, rating }

/// Kichik pill-shakl belgi — chegirma foizi, holat, sharh soni va h.k. uchun.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.text, this.variant = AppBadgeVariant.primary});

  final String text;
  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final success = isDark ? AppColors.success : AppColors.success;
    final error = isDark ? AppColors.error : AppColors.error;
    final rating = isDark ? AppColors.rating : AppColors.rating;

    final Color bg;
    final Color fg;
    switch (variant) {
      case AppBadgeVariant.primary:
        bg = primary;
        fg = Colors.white;
      case AppBadgeVariant.success:
        bg = success;
        fg = Colors.white;
      case AppBadgeVariant.error:
        bg = error;
        fg = Colors.white;
      case AppBadgeVariant.rating:
        bg = rating.withValues(alpha: 0.15);
        fg = rating;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}
