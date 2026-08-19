import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Tarmoq/server xatosi holati — "Qayta urinish" tugmasi bilan.
class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.error : AppColors.error;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondary;
    final h2 = isDark ? AppTypography.h2 : AppTypography.h2;
    final body = isDark ? AppTypography.body : AppTypography.body;

    final msg = error.toString();
    final isOffline = msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('Failed host lookup');

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.wifi_off_outlined : Icons.error_outline,
              size: 64.sp,
              color: errorColor,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              isOffline ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi',
              style: h2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              isOffline
                  ? 'Internetga ulanib, qayta urinib ko\'ring'
                  : 'Server bilan bog\'lanishda muammo. Qayta urinib ko\'ring.',
              textAlign: TextAlign.center,
              style: body.copyWith(color: textSecondary),
            ),
            SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Qayta urinish',
              icon: Icons.refresh,
              onPressed: onRetry,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
