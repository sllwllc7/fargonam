import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_colors.dart';
import '../app_gradients.dart';
import '../app_motion.dart';
import '../app_shadows.dart';

const _cartIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M5 8h14l-1.2 10.5a2 2 0 0 1-2 1.5H8.2a2 2 0 0 1-2-1.5Z" stroke="#000" stroke-width="1.8" stroke-linejoin="round" fill="none"/>'
    '<path d="M9 10V6a3 3 0 0 1 6 0v4" stroke="#000" stroke-width="1.8" stroke-linecap="round" fill="none"/></svg>';

/// Savat FAB — dc.html CART FAB bo'limidan tasdiqlangan. Chaqiruvchi ekran
/// ko'rsatish shartini (5.0/10-bo'lim: Market/kategoriya/to'plamda doim,
/// bosh sahifada savat bo'sh bo'lmaganda) o'zi hal qiladi.
class CartFab extends StatefulWidget {
  const CartFab({super.key, required this.cartCount, required this.onTap});
  final int cartCount;
  final VoidCallback onTap;

  @override
  State<CartFab> createState() => _CartFabState();
}

class _CartFabState extends State<CartFab> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _entranceScale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: AppMotion.pop);
    _entranceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.15), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _entrance, curve: AppMotion.standard));
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 104 + MediaQuery.paddingOf(context).bottom,
      child: AnimatedBuilder(
        animation: _entranceScale,
        builder: (context, child) => Transform.scale(scale: _entranceScale.value, child: child),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1.0,
            duration: AppMotion.pressedDuration,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.bubble,
                    boxShadow: AppShadows.fab,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.string(
                    _cartIconSvg,
                    width: 25,
                    height: 25,
                    colorFilter: const ColorFilter.mode(AppColors.ctaText, BlendMode.srcIn),
                  ),
                ),
                if (widget.cartCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.cartCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
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
