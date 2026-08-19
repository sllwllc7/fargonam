import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, text }

/// Kutuku tugma — to'liq yumaloq (pill), ikona + matn birga bo'lishi mumkin.
/// `variant`: primary (to'ldirilgan), secondary (outline), text (faqat matn).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final border = isDark ? AppColors.border : AppColors.border;
    final disabled = onPressed == null || loading;

    final content = loading
        ? SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary ? Colors.white : primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20.sp),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    final height = 54.h;
    final radius = BorderRadius.circular(AppRadius.button);

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: FilledButton(
            onPressed: disabled ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              disabledBackgroundColor: primary.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: radius),
              textStyle: AppTypography.title.copyWith(color: Colors.white),
            ),
            child: content,
          ),
        );
      case AppButtonVariant.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height,
          child: OutlinedButton(
            onPressed: disabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(borderRadius: radius),
              textStyle: AppTypography.title.copyWith(color: primary),
            ),
            child: content,
          ),
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: AppTypography.title.copyWith(color: primary),
          ),
          child: content,
        );
    }
  }
}
