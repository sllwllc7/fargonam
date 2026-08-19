import 'package:flutter/material.dart';

import '../app_motion.dart';

/// Ro'yxat/karta elementi kirishi — dc.html `animation:fadeUp` (5.2): 10px
/// pastdan yuqoriga + fade, standart egri chiziq. `delay` — dc.html'dagi
/// `animation-delay` (masalan ro'yxatda `index * AppMotion.staggerStep`).
class FadeUpItem extends StatefulWidget {
  const FadeUpItem({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<FadeUpItem> createState() => _FadeUpItemState();
}

class _FadeUpItemState extends State<FadeUpItem> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.fadeUp);
    _curved = CurvedAnimation(parent: _ctrl, curve: AppMotion.standard);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
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
          offset: Offset(0, (1 - _curved.value) * AppMotion.fadeUpOffset),
          child: child,
        ),
      ),
    );
  }
}
