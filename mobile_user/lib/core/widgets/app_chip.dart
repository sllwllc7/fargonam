import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Tanlanadigan chip — kategoriya filtri, variant tanlash (o'lcham/rang) uchun.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final surface = isDark ? AppColors.surface : AppColors.surface;
    final border = isDark ? AppColors.border : AppColors.border;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondary;
    final caption = isDark ? AppTypography.caption : AppTypography.caption;

    final bg = selected ? primary : surface;
    final fg = enabled ? (selected ? Colors.white : textPrimary) : textSecondary;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: selected ? null : Border.all(color: border, width: 0.75.w),
          ),
          child: Text(label, style: caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
