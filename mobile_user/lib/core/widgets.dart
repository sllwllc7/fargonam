import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_colors.dart';

/// Internet yo'q yoki server xatosi uchun umumiy widget.
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = error.toString();
    final isOffline = msg.contains('SocketException') || msg.contains('Connection refused') || msg.contains('Failed host lookup');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: isOffline ? const Color(0xFFC77B1E) /* DESIGN.md warning */ : AppColorsDark.error,
            ),
            const SizedBox(height: 16),
            Text(
              isOffline ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isOffline
                  ? 'Internetga ulanib, qayta urinib ko\'ring'
                  : 'Server bilan bog\'lanishda muammo. Qayta urinib ko\'ring.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColorsDark.textSecondary.withValues(alpha: 0.7), fontSize: 14),
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

/// AsyncValue uchun yordamchi extension — error/loading/data ni bir joyda boshqarish.
extension AsyncValueUI<T> on AsyncValue<T> {
  Widget whenWidget({
    required Widget Function(T data) data,
    required void Function() onRetry,
    Widget Function()? loading,
  }) {
    return when(
      loading: loading ?? () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorRetryWidget(error: e, onRetry: onRetry),
      data: data,
    );
  }
}

/// Shimmer/skeleton loading effekti.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, required this.width, required this.height, this.borderRadius = 12});
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
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
                AppColorsDark.surface,
                AppColorsDark.surfaceAlt,
                AppColorsDark.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bo'sh holat uchun umumiy widget.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key, required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColorsDark.border),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColorsDark.textSecondary)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColorsDark.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cached network image — shimmer placeholder bilan.
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.iconSize = 24,
  });
  final String url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: AppColorsDark.surfaceAlt,
          child: Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColorsDark.textSecondary.withValues(alpha: 0.7)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: AppColorsDark.surfaceAlt,
          child: Icon(Icons.image_not_supported_outlined, color: AppColorsDark.textSecondary.withValues(alpha: 0.7), size: iconSize),
        ),
      ),
    );
  }
}
