import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../orders/order_tracking_screen.dart';
import '../shell/app_shell.dart' show appShellKey;

const _checkIconSvg =
    '<svg viewBox="0 0 24 24"><path d="m5 12.5 4.5 4.5L19 7.5" stroke="#000" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>';

/// Muvaffaqiyat — HANDOFF.md 2-bo'lim, 8-band.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});
  final Map<String, dynamic> order;

  void _backToHome(BuildContext context) {
    appShellKey.currentState?.switchTab(2);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Orqaga tugmasi Checkout'ga qaytmasin — buyurtma allaqachon berilgan.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _backToHome(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ScreenFadeIn(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.4, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: SvgPicture.string(_checkIconSvg, width: 40, height: 40),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('Buyurtma qabul qilindi!', style: AppTypography.h2.copyWith(fontSize: 22, letterSpacing: -0.4)),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: AppTypography.body.copyWith(height: 1.5, color: AppColors.textMuted, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Buyurtma raqami: '),
                          TextSpan(text: 'FN-${order['id']}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const TextSpan(text: '\nKuryer yetkazib berganda to\'laysiz'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),
                    PressableScale(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        pushReplacementAppRoute(context, (_) => OrderTrackingScreen(order: order));
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(gradient: AppGradients.cta, borderRadius: BorderRadius.circular(AppRadius.button), boxShadow: AppShadows.cta),
                        alignment: Alignment.center,
                        child: Text('Buyurtmani kuzatish', style: AppTypography.button),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _backToHome(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text('Bosh sahifaga qaytish', style: AppTypography.cardTitleSm.copyWith(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
