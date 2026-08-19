import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';

/// Taxi tab — 1-bosqichda faqat "Tez orada" skeleti (HANDOFF.md, MVP-1 qamrovi).
///
/// To'liq taksi buyurtma oqimi `taxi_screen.dart`da saqlanadi (2-bosqichda
/// qayta ulanadi) — bu ekran shunchaki uni almashtiradi.
class TaxiComingSoonScreen extends StatelessWidget {
  const TaxiComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: AppMotion.pop,
              curve: AppMotion.screenInCurve,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88.w,
                    height: 88.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE9FE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_taxi_outlined, size: 38.sp, color: AppColors.textMuted),
                  ),
                  SizedBox(height: 22.h),
                  Text('Fargonam Taxi', style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark)),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Tez orada ishga tushadi',
                      style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Farg\'ona vodiysi bo\'ylab tez va qulay taksi xizmati ustida ishlayapmiz. '
                    'Ishga tushganda sizga xabar beramiz.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted, height: 1.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
