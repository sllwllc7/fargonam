import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Kutuku input maydoni — label doim ustida (yo'qolmaydi), yumaloq chegara.
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textPrimary;
    final surface = isDark ? AppColors.surface : AppColors.surface;
    final border = isDark ? AppColors.border : AppColors.border;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final titleStyle = isDark ? AppTypography.title : AppTypography.title;
    final bodyStyle = isDark ? AppTypography.body : AppTypography.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: titleStyle),
        SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          style: bodyStyle.copyWith(color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: surface,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primary) : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16.h),
          ),
        ),
      ],
    );
  }
}
