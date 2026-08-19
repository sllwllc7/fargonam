import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _taxiIconSvg = '<svg viewBox="0 0 24 24">'
    '<path d="M4 13l1.5-4.5A2 2 0 0 1 7.4 7h9.2a2 2 0 0 1 1.9 1.5L20 13v5h-2.5v-1.5h-11V18H4Z" stroke="#3F3F49" stroke-width="1.7" stroke-linejoin="round" fill="none"/>'
    '<circle cx="7.5" cy="14" r="1.2" fill="#3F3F49"/>'
    '<circle cx="16.5" cy="14" r="1.2" fill="#3F3F49"/>'
    '</svg>';

/// Taxi tab — 1-bosqichda faqat "Tez orada" skeleti (HANDOFF.md, MVP-1 qamrovi).
///
/// To'liq taksi buyurtma oqimi `taxi_screen.dart`da saqlanadi (2-bosqichda
/// qayta ulanadi) — bu ekran shunchaki uni almashtiradi.
class TaxiComingSoonScreen extends StatelessWidget {
  const TaxiComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: AppMotion.pop,
                curve: AppMotion.screenInCurve,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: SvgPicture.string(_taxiIconSvg, width: 38, height: 38),
                    ),
                    const SizedBox(height: 22),
                    Text('Fargonam Taxi', style: AppTypography.h2.copyWith(fontSize: 22, letterSpacing: -0.4)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                      child: Text('Tez orada ishga tushadi', style: AppTypography.formSectionLabel.copyWith(letterSpacing: 0)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Farg\'ona vodiysi bo\'ylab tez va qulay taksi xizmati ustida ishlayapmiz. '
                      'Ishga tushganda sizga xabar beramiz.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(color: AppColors.textMuted, height: 1.55),
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
