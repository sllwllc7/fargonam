import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_colors.dart';
import '../app_motion.dart';

const _heartPath = 'M10 17 3.6 10.8a4 4 0 1 1 5.7-5.7L10 5.8l.7-.7a4 4 0 1 1 5.7 5.7Z';
const _heartOutline = '<svg viewBox="0 0 20 20"><path d="$_heartPath" fill="none" stroke="#000" stroke-width="1.5"/></svg>';
const _heartFilled = '<svg viewBox="0 0 20 20"><path d="$_heartPath" fill="#000" stroke="#000" stroke-width="1.5"/></svg>';

/// Sevimli yurakcha — dc.html'da Kategoriya/Mahsulot/Sevimlilar ekranlarida
/// bir xil ishlatiladi. `active`ga o'tishda `AppMotion.pop` bilan kichik pop.
/// Rang dc.html manba kodidan (`pdFavFill`/`pdFavStroke`) tasdiqlangan —
/// qizil EMAS, `textMuted`/`textSecondary` (neytral).
class FavoriteHeartIcon extends StatelessWidget {
  const FavoriteHeartIcon({
    super.key,
    required this.active,
    this.size = 14,
    this.activeColor = AppColors.textMuted,
    this.inactiveColor = AppColors.textSecondary,
  });
  final bool active;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: active ? 0.6 : 1, end: 1),
      duration: AppMotion.pop,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: SvgPicture.string(
        active ? _heartFilled : _heartOutline,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(active ? activeColor : inactiveColor, BlendMode.srcIn),
      ),
    );
  }
}
