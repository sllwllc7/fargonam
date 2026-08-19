import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_colors.dart';
import '../app_gradients.dart';
import '../app_motion.dart';
import '../app_shadows.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Suzuvchi tab bar — 5 ta bosh navigatsiya (Market, Taxi, Asosiy, AI, Profil).
/// dc.html TAB BAR bo'limidan tasdiqlangan: faol tab bo'rtmasi
/// `translateY(-24px)` bilan spring egri chiziq (`cubic-bezier(.3,1.6,.5,1)`)
/// bo'yicha ko'tariladi, atrofida bar rangida 5px halqa hosil bo'ladi.
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({super.key, required this.activeIndex, required this.onTap});

  /// 0 Market, 1 Taxi, 2 Asosiy, 3 AI, 4 Profil.
  final int activeIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _TabItem(icon: _TabIcons.market, label: 'Market'),
    _TabItem(icon: _TabIcons.taxi, label: 'Taxi'),
    _TabItem(icon: _TabIcons.home, label: 'Asosiy'),
    _TabItem(icon: _TabIcons.ai, label: 'AI'),
    _TabItem(icon: _TabIcons.profile, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    // 5.4: gesture-bar ustiga chiqib ketmasin — tizim pastki bo'shlig'i
    // dc.html'dagi 14px ustiga qo'shiladi.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: AppSizes.tabBarSideInset,
      right: AppSizes.tabBarSideInset,
      bottom: AppSizes.tabBarBottomInset + bottomInset,
      child: Container(
        height: AppSizes.tabBarHeight,
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
        decoration: BoxDecoration(
          color: AppColors.tabBar,
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppShadows.tabBar,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _TabButton(
                  item: _items[i],
                  active: activeIndex == i,
                  onTap: () {
                    if (activeIndex != i) HapticFeedback.lightImpact();
                    onTap(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({required this.item, required this.active, required this.onTap});
  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: AppMotion.pressedDuration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppMotion.tabTransform,
              curve: AppMotion.tabSpring,
              transform: Matrix4.translationValues(0, active ? -24 : 0, 0),
              width: 50,
              height: 50,
              child: AnimatedContainer(
                duration: AppMotion.tabColor,
                curve: Curves.ease,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: active ? AppGradients.tabBubble : null,
                  border: Border.all(
                    color: active ? AppColors.tabBar : Colors.transparent,
                    width: 5,
                  ),
                  boxShadow: active ? AppShadows.tabBubble : null,
                ),
                child: SvgPicture.string(
                  widget.item.icon,
                  width: 23,
                  height: 23,
                  colorFilter: ColorFilter.mode(
                    active ? AppColors.tabIconActive : AppColors.tabIconInactive,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: AppMotion.tabTransform,
              curve: AppMotion.tabSpring,
              transform: Matrix4.translationValues(0, active ? -20 : 0, 0),
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.tabColor,
                curve: Curves.ease,
                style: AppTypography.small.copyWith(
                  fontSize: 11,
                  color: active ? AppColors.tabLabelActive : AppColors.tabLabelInactive,
                ),
                child: Text(widget.item.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final String icon;
  final String label;
}

/// dc.html `tabIcons` obyektidagi SVG `path d` qiymatlaridan ko'chirilgan.
class _TabIcons {
  static const home =
      '<svg viewBox="0 0 24 24"><path d="M4.5 10.2 12 4l7.5 6.2M6 8.8V19a1.5 1.5 0 0 0 1.5 1.5h9A1.5 1.5 0 0 0 18 19V8.8M10 20.5v-5.5a2 2 0 0 1 4 0v5.5" stroke="#000" stroke-width="1.9" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';
  static const market =
      '<svg viewBox="0 0 24 24"><path d="M2.5 3h2L5 5m0 0 1.7 9a2 2 0 0 0 2 1.6h7.8a2 2 0 0 0 2-1.6L20 5H5ZM8.2 20.2a.9.9 0 1 0 1.8 0 .9.9 0 0 0-1.8 0ZM16.2 20.2a.9.9 0 1 0 1.8 0 .9.9 0 0 0-1.8 0Z" stroke="#000" stroke-width="1.9" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';
  static const taxi =
      '<svg viewBox="0 0 24 24"><path d="M5 11.5 6.3 7.6A2 2 0 0 1 8.2 6.2h7.6a2 2 0 0 1 1.9 1.4L19 11.5M5 11.5h14M5 11.5a2 2 0 0 0-1.5 2v3.3h2.2v-1.4h12.6v1.4h2.2v-3.3a2 2 0 0 0-1.5-2M7.2 14.2h.01M16.8 14.2h.01" stroke="#000" stroke-width="1.9" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';
  static const ai =
      '<svg viewBox="0 0 24 24"><path d="M12 3.5c.6 3.8 1.9 5.1 5.7 5.7-3.8.6-5.1 1.9-5.7 5.7-.6-3.8-1.9-5.1-5.7-5.7 3.8-.6 5.1-1.9 5.7-5.7ZM18 15.5c.3 1.9 1 2.6 2.9 2.9-1.9.3-2.6 1-2.9 2.9-.3-1.9-1-2.6-2.9-2.9 1.9-.3 2.6-1 2.9-2.9Z" stroke="#000" stroke-width="1.9" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';
  static const profile =
      '<svg viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M12 3a4 4 0 1 0 0 8 4 4 0 0 0 0-8Z" stroke="#000" stroke-width="1.9" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';
}
