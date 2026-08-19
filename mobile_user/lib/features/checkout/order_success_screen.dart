import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../orders/order_tracking_screen.dart';
import '../shell/app_shell.dart' show appShellKey;

/// Muvaffaqiyat — HANDOFF.md 2-bo'lim, 8-band.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 88.w,
                    height: 88.w,
                    decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                    child: Icon(Icons.check, size: 40.sp, color: AppColors.primaryDark),
                  ),
                ),
                SizedBox(height: 22.h),
                Text('Buyurtma qabul qilindi!', style: AppTextStyles.h2.copyWith(fontSize: 22)),
                SizedBox(height: 8.h),
                Text.rich(
                  TextSpan(
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 14, height: 1.5),
                    children: [
                      const TextSpan(text: 'Buyurtma raqami: '),
                      TextSpan(text: 'FN-${order['id']}', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                      const TextSpan(text: '\nKuryer yetkazib berganda to\'laysiz'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 26.h),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)));
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54.h,
                    decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(AppRadius.button), boxShadow: AppShadows.primaryButton),
                    child: Center(child: Text('Buyurtmani kuzatish', style: AppTextStyles.button)),
                  ),
                ),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    appShellKey.currentState?.switchTab(2);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Text('Bosh sahifaga qaytish', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
