import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_motion.dart';

/// Toast — dc.html TOAST bo'limidan tasdiqlangan. Pastdan chiqadi, "Savat"
/// havolasi bilan; `AppMotion.toastVisible` (2.4s) dan keyin o'zi yopiladi.
class AppToast extends StatelessWidget {
  const AppToast({super.key, required this.message, this.onCartTap});
  final String message;
  final VoidCallback? onCartTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 100 + MediaQuery.paddingOf(context).bottom,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xF2171327),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const _CheckIcon(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                if (onCartTap != null)
                  GestureDetector(
                    onTap: onCartTap,
                    child: const Text(
                      'Savat',
                      style: TextStyle(color: Colors.black, fontSize: 13.5, fontWeight: FontWeight.w700),
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

class _CheckIcon extends StatelessWidget {
  const _CheckIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(11, 9), painter: _CheckPainter());
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEEF1F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.09, size.height * 0.5)
      ..lineTo(size.width * 0.41, size.height)
      ..lineTo(size.width, size.height * 0.1);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ekran ustiga toast ko'rsatadi, `AppMotion.toastVisible` dan keyin
/// avtomatik yopadi. `AppMotion.toastIn` (300ms, standart egri chiziq) bilan
/// pastdan suzib chiqadi.
void showAppToast(BuildContext context, String message, {VoidCallback? onCartTap}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  Timer? timer;

  entry = OverlayEntry(
    builder: (context) => _AnimatedToast(
      message: message,
      onCartTap: onCartTap == null
          ? null
          : () {
              timer?.cancel();
              entry.remove();
              onCartTap();
            },
    ),
  );

  overlay.insert(entry);
  timer = Timer(AppMotion.toastVisible, () {
    if (entry.mounted) entry.remove();
  });
}

class _AnimatedToast extends StatefulWidget {
  const _AnimatedToast({required this.message, this.onCartTap});
  final String message;
  final VoidCallback? onCartTap;

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.toastIn)..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _ctrl, curve: AppMotion.standard);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 12),
          child: Transform.scale(scale: 0.95 + 0.05 * curved.value, child: child),
        ),
      ),
      child: AppToast(message: widget.message, onCartTap: widget.onCartTap),
    );
  }
}
