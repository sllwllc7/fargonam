import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import 'auth_providers.dart';

enum _Stage { initial, waiting, expired }

class TelegramLoginScreen extends ConsumerStatefulWidget {
  const TelegramLoginScreen({super.key});
  @override
  ConsumerState<TelegramLoginScreen> createState() => _TelegramLoginScreenState();
}

class _TelegramLoginScreenState extends ConsumerState<TelegramLoginScreen> {
  _Stage _stage = _Stage.initial;
  String? _sessionId;
  Timer? _pollTimer;
  String? _error;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLogin() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _error = null;
    });
    final session = await ref.read(authControllerProvider.notifier).startTelegramLogin();
    if (session == null) {
      HapticFeedback.heavyImpact();
      setState(() => _error = ref.read(authControllerProvider).error ?? 'Xatolik yuz berdi');
      return;
    }
    _sessionId = session.sessionId;
    final httpsUri = Uri.parse(session.botUrl);
    // Avval Telegram ilovasini to'g'ridan-to'g'ri ochadigan tg:// sxemasini sinaymiz —
    // https://t.me link ba'zan brauzer/web versiyasini ochib yuboradi.
    final username = httpsUri.pathSegments.isNotEmpty ? httpsUri.pathSegments.first : '';
    final startParam = httpsUri.queryParameters['start'] ?? '';
    final tgUri = Uri.parse('tg://resolve?domain=$username&start=$startParam');

    bool opened = false;
    try {
      opened = await launchUrl(tgUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      opened = await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
    }
    if (!opened) {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Telegram ilovasini ochib bo\'lmadi. Telegram o\'rnatilganini tekshiring.');
      return;
    }
    setState(() => _stage = _Stage.waiting);
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final sessionId = _sessionId;
      if (sessionId == null) return;
      final result = await ref.read(authControllerProvider.notifier).pollTelegramSession(sessionId);
      if (!mounted) return;
      if (result == true) {
        _pollTimer?.cancel();
        HapticFeedback.mediumImpact();
      } else if (result == null) {
        _pollTimer?.cancel();
        setState(() => _stage = _Stage.expired);
      }
    });
  }

  void _retry() {
    _pollTimer?.cancel();
    _sessionId = null;
    setState(() {
      _stage = _Stage.initial;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).loading;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (_stage) {
                _Stage.initial => _InitialStage(
                    key: const ValueKey('initial'),
                    loading: loading,
                    error: _error,
                    onSubmit: _startLogin,
                  ),
                _Stage.waiting => _WaitingStage(
                    key: const ValueKey('waiting'),
                    onCancel: _retry,
                  ),
                _Stage.expired => _ExpiredStage(
                    key: const ValueKey('expired'),
                    onRetry: _retry,
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialStage extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _InitialStage({
    super.key,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.cream, AppColors.creamDim],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cream.withValues(alpha: 0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.business_center,
                size: 42, color: AppColors.midnightIndigo),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Fargonam Biznes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Davom etish uchun Telegram orqali kiring',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 36),
        _ErrorBox(error: error),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: loading
                ? const SizedBox.shrink()
                : const Icon(Icons.telegram, size: 22),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF229ED9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            label: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Telegram orqali kirish',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _WaitingStage extends StatelessWidget {
  final VoidCallback onCancel;
  const _WaitingStage({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Center(
          child: SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: AppColors.cream),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Telegramda tasdiqlang',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ochilgan Telegram botida "Start" tugmasini bosing. Tasdiqlangach avtomatik kirasiz.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 28),
        TextButton(
          onPressed: onCancel,
          child: const Text(
            'Bekor qilish',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ExpiredStage extends StatelessWidget {
  final VoidCallback onRetry;
  const _ExpiredStage({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Center(
          child: Icon(Icons.timer_off_outlined,
              size: 64, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        const Text(
          'Sessiya muddati tugadi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Qaytadan urinib ko\'ring',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Qaytadan urinish',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String? error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
