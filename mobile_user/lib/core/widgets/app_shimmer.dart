import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Yuklanish skeletoni — shimmer effekt bilan.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final double? borderRadius;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surface : AppColors.surface;
    final highlight = isDark ? AppColors.surfaceAlt : AppColors.surfaceAlt;
    final radius = widget.borderRadius ?? AppRadius.card;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final value = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * value, 0),
              end: Alignment(-1.0 + 2.0 * value + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
