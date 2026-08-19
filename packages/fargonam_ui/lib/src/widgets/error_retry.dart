import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_radius.dart';
import '../app_typography.dart';

/// Internet yo'q yoki server xatosi uchun umumiy widget — light palitrada.
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({super.key, required this.error, required this.onRetry});
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
              color: isOffline ? AppColors.warning : AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              isOffline ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 8),
            Text(
              isOffline ? 'Internetga ulanib, qayta urinib ko\'ring' : 'Server bilan bog\'lanishda muammo',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }
}
