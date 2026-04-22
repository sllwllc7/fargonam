import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Bildirishnomalar'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        actions: [
          notifsAsync.maybeWhen(
            data: (notifs) {
              final hasUnread = notifs.any((n) => n['is_read'] != true);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await ref
                      .read(dioProvider)
                      .post('/notifications/read-all');
                  ref.invalidate(notificationsProvider);
                  ref.invalidate(unreadCountProvider);
                },
                icon: const Icon(Icons.done_all,
                    size: 18, color: AppColors.cream),
                label: const Text(
                  'Hammasi',
                  style: TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w700),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const _NotifsSkeleton(),
        error: (e, _) => ErrorRetryWidget(
          error: e,
          onRetry: () {
            ref.invalidate(notificationsProvider);
            ref.invalidate(unreadCountProvider);
          },
        ),
        data: (notifs) {
          if (notifs.isEmpty) return const _EmptyNotifsState();
          return RefreshIndicator(
            color: AppColors.cream,
            backgroundColor: AppColors.surfaceHigh,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: notifs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final n = notifs[i];
                return _NotificationTile(
                  notification: n,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    if (n['is_read'] != true) {
                      await ref.read(dioProvider).post(
                          '/notifications/${n['id']}/read');
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadCountProvider);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatefulWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _pressed = false;

  (IconData, Color) _typeIcon(String type) => switch (type) {
        'order' => (Icons.receipt_long, AppColors.info),
        'ride' => (Icons.local_taxi, AppColors.warning),
        'chat' => (Icons.chat_bubble, AppColors.success),
        'promo' => (Icons.campaign, AppColors.cream),
        _ => (Icons.notifications, AppColors.textSecondary),
      };

  String _formatTime(String time) {
    final dt = DateTime.tryParse(time);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Hozir';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isRead = n['is_read'] == true;
    final (icon, color) = _typeIcon((n['type'] as String?) ?? 'info');

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead
                ? AppColors.surface
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isRead
                  ? AppColors.divider
                  : color.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            (n['title'] as String?) ?? '',
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime((n['created_at'] as String?) ?? ''),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (n['body'] as String?) ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isRead
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifsState extends StatelessWidget {
  const _EmptyNotifsState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.notifications_none,
                size: 56,
                color: AppColors.cream.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bildirishnomalar yo\'q',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Yangi xabar kelganda\nshu yerda ko\'rinadi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifsSkeleton extends StatelessWidget {
  const _NotifsSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerBox(width: 44, height: 44, borderRadius: 13),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 14),
                  SizedBox(height: 6),
                  ShimmerBox(width: double.infinity, height: 12),
                  SizedBox(height: 4),
                  ShimmerBox(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
