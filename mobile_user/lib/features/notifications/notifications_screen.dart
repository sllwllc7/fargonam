import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import 'notifications_providers.dart';

/// Bildirishnomalar — HANDOFF.md 2-bo'lim, 11-band.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.maybePop(context);
                    },
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                      child: Icon(Icons.arrow_back_ios_new, size: 15.sp, color: AppColors.text),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(child: Text('Bildirishnomalar', style: AppTextStyles.title)),
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
                        child: Text('Hammasi', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5, color: AppColors.text)),
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
                error: (e, _) => Center(child: Text('Yuklab bo\'lmadi', style: AppTextStyles.caption)),
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
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                      itemCount: notifs.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, i) {
                        final n = notifs[i];
                        return _NotificationTile(
                          notification: n,
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            if (n['is_read'] != true) {
                              await ref.read(dioProvider).post('/notifications/${n['id']}/read');
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
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  (IconData, Color, Color) _typeStyle(String type) => switch (type) {
        'order' || 'seller_order' => (Icons.receipt_long_outlined, const Color(0xFFEDE9FE), AppColors.primaryDark),
        'ride' => (Icons.local_taxi_outlined, AppColors.warningSoft, AppColors.warning),
        'chat' => (Icons.chat_bubble_outline, AppColors.successSoft, AppColors.success),
        'promo' => (Icons.campaign_outlined, const Color(0xFFEDE9FE), AppColors.primaryDark),
        _ => (Icons.notifications_outlined, AppColors.bg, AppColors.textSecondary),
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
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, decoration: BoxDecoration(color: isRead ? Colors.transparent : fg, borderRadius: BorderRadius.circular(2))),
              SizedBox(width: 11.w),
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.r)),
                child: Icon(icon, color: fg, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text((n['title'] as String?) ?? '', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14)),
                        ),
                        SizedBox(width: 8.w),
                        Text(_formatTime((n['created_at'] as String?) ?? ''), style: AppTextStyles.small.copyWith(fontSize: 11)),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text((n['body'] as String?) ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 12.5, height: 1.4)),
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
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bildirishnomalar yo\'q', style: AppTextStyles.cardTitle),
            SizedBox(height: 6.h),
            Text('Buyurtmangiz tayyor bo\'lganda shu yerda xabar keladi', textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
