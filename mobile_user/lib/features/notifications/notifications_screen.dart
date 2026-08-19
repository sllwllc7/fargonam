import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import 'notifications_providers.dart';

/// dc.html'da buyurtma bildirishnomasi ikonkasi (`NI.ready`) — real backend
/// `type`da prep/ready/done kabi ichki bosqich yo'q (faqat "order"/"seller_order"),
/// shu sabab eng ko'p uchraydigan holat (tayyor bo'ldi/topshirildi) ikonkasi
/// ishlatiladi.
const _orderIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M5 8h14l-1.2 10.5a2 2 0 0 1-2 1.5H8.2a2 2 0 0 1-2-1.5ZM9 10V6a3 3 0 0 1 6 0v4" stroke="#000" stroke-width="1.7" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';

/// Bildirishnomalar — HANDOFF.md 2-bo'lim, 11-band.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    BackCircleButton(onTap: () => Navigator.maybePop(context)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Bildirishnomalar', style: AppTypography.title)),
                    notifsAsync.maybeWhen(
                      data: (notifs) {
                        final hasUnread = notifs.any((n) => n['is_read'] != true);
                        if (!hasUnread) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await ref.read(dioProvider).post('/notifications/read-all');
                            ref.invalidate(notificationsProvider);
                            ref.invalidate(unreadCountProvider);
                          },
                          child: Text('Hammasi', style: AppTypography.rowTitle.copyWith(fontSize: 13.5)),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notifsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text('Yuklab bo\'lmadi', style: AppTypography.caption)),
                  data: (notifs) {
                    if (notifs.isEmpty) return const _EmptyNotifsState();
                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        ref.invalidate(notificationsProvider);
                        ref.invalidate(unreadCountProvider);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        itemCount: notifs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final n = notifs[i];
                          return FadeUpItem(
                            delay: AppMotion.staggerStep * i,
                            child: _NotificationTile(
                              notification: n,
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                if (n['is_read'] != true) {
                                  await ref.read(dioProvider).post('/notifications/${n['id']}/read');
                                  ref.invalidate(notificationsProvider);
                                  ref.invalidate(unreadCountProvider);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  (Widget, Color, Color) _typeStyle(String type) => switch (type) {
        'order' || 'seller_order' => (SvgPicture.string(_orderIconSvg, width: 18, height: 18), AppColors.primaryLight, AppColors.textPrimary),
        'ride' => (const Icon(Icons.local_taxi_outlined, size: 18, color: AppColors.warning), AppColors.warningSoft, AppColors.warning),
        'chat' => (const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.success), AppColors.successTint, AppColors.success),
        'promo' => (const Icon(Icons.campaign_outlined, size: 18, color: AppColors.textPrimary), AppColors.primaryLight, AppColors.textPrimary),
        _ => (const Icon(Icons.notifications_outlined, size: 18, color: AppColors.textSecondary), AppColors.background, AppColors.textSecondary),
      };

  String _formatTime(String time) {
    final dt = DateTime.tryParse(time);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Hozir';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daq';
    if (diff.inHours < 24) return '${diff.inHours} soat';
    if (diff.inDays < 7) return '${diff.inDays} kun';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isRead = n['is_read'] == true;
    final (icon, bg, fg) = _typeStyle((n['type'] as String?) ?? 'info');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.groupedCard),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, decoration: BoxDecoration(color: isRead ? Colors.transparent : fg, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 11),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.input)),
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text((n['title'] as String?) ?? '', style: AppTypography.cardTitleSm.copyWith(fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        Text(_formatTime((n['created_at'] as String?) ?? ''), style: AppTypography.small.copyWith(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text((n['body'] as String?) ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
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
            Text('Bildirishnomalar yo\'q', style: AppTypography.cardTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 6),
            Text('Buyurtmangiz tayyor bo\'lganda shu yerda xabar keladi', textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
