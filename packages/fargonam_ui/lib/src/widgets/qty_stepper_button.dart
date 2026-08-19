import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import 'pressable_scale.dart';

/// Miqdor stepper tugmasi (− / +) — dc.html'da matn belgisi sifatida
/// ishlatiladi (ikon emas). Mahsulot sahifasi va Savat qatorlarida
/// bir xil, faqat o'lcham farqli.
class QtyStepperButton extends StatelessWidget {
  const QtyStepperButton({
    super.key,
    required this.label,
    required this.fontSize,
    required this.onTap,
    this.size = 40,
  });
  final String label;
  final double fontSize;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.85,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}
