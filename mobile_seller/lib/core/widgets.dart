import 'package:flutter/material.dart';

import 'theme.dart';

/// Tugma bir marta bosilganda qayta bosilmasligi uchun guard.
bool _actionBusy = false;
Future<void> guardedAction(Future<void> Function() action) async {
  if (_actionBusy) return;
  _actionBusy = true;
  try {
    await action();
  } finally {
    _actionBusy = false;
  }
}

/// Internet yo'q yoki server xatosi uchun umumiy widget.
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget(
      {super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = error.toString();
    final isOffline = msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('Failed host lookup');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: isOffline ? AppColors.warning : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isOffline
                  ? 'Internet aloqasi yo\'q'
                  : 'Xatolik yuz berdi',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isOffline
                  ? 'Internetga ulanib, qayta urinib ko\'ring'
                  : 'Server bilan bog\'lanishda muammo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer/skeleton loading effekti.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox(
      {super.key,
      required this.width,
      required this.height,
      this.borderRadius = 12});
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final value = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * value, 0),
              end: Alignment(-1.0 + 2.0 * value + 1, 0),
              colors: const [
                AppColors.surfaceHigh,
                AppColors.surfaceBright,
                AppColors.surfaceHigh,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pressable scale wrapper
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
  });
  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// Narxni chiroyli formatlash: 1250000 -> 1 250 000 UZS
String formatPrice(num value) {
  final intStr = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf UZS';
}
