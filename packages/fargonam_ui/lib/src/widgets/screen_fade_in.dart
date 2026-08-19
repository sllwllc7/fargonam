import 'package:flutter/material.dart';

import '../app_motion.dart';

/// Ekran kirishi — dc.html `animation:screenIn` (5.2): 320ms, standart egri
/// chiziq, translateX(14px)→0 + fade. Ekran birinchi chizilganda bir marta
/// ishga tushadi (`IndexedStack` bilan tab qayta ko'rsatilganda emas).
class ScreenFadeIn extends StatefulWidget {
  const ScreenFadeIn({super.key, required this.child});
  final Widget child;

  @override
  State<ScreenFadeIn> createState() => _ScreenFadeInState();
}

class _ScreenFadeInState extends State<ScreenFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.screenIn)..forward();
    _curved = CurvedAnimation(parent: _ctrl, curve: AppMotion.standard);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curved.value,
        child: Transform.translate(
          offset: Offset((1 - _curved.value) * AppMotion.screenInOffset, 0),
          child: child,
        ),
      ),
    );
  }
}
