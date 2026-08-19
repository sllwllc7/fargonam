import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_colors.dart';
import 'pressable_scale.dart';

const _chevronSvg =
    '<svg viewBox="0 0 8 14"><path d="M7 1 1 7l6 6" stroke="#000" stroke-width="2" stroke-linecap="round" fill="none"/></svg>';

/// 36x36 dumaloq "orqaga" tugmasi — dc.html'da Kategoriya/Kit/Checkout/
/// Kuzatish/Bildirishnomalar ekranlarida bir xil ishlatiladi.
class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.92,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.border, blurRadius: 2, offset: const Offset(0, 1))],
        ),
        alignment: Alignment.center,
        child: SvgPicture.string(_chevronSvg, width: 9, height: 15),
      ),
    );
  }
}
