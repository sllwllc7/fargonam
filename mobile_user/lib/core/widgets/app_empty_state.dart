import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Bo'sh holat (bo'sh savat, bo'sh sevimlilar, natija topilmadi va h.k.).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondary;
    final h2 = isDark ? AppTypography.h2 : AppTypography.h2;
    final body = isDark ? AppTypography.body : AppTypography.body;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.sp, color: textSecondary),
            SizedBox(height: AppSpacing.lg),
            Text(title, style: h2, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: body.copyWith(color: textSecondary),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
