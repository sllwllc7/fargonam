import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../cart/cart_screen.dart' show cartProvider;
import '../notifications/notifications_providers.dart';
import '../notifications/notifications_screen.dart';
import '../orders/orders_screen.dart' show myOrdersProvider, OrdersScreen;
import '../shell/app_shell.dart' show appShellKey;

final newsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/news', queryParameters: {'limit': 10});
  return (res.data['items'] as List).cast<Map<String, dynamic>>();
});

/// Bosh sahifa — HANDOFF.md 2-bo'lim, 1-band. Salom + "Fargonam"; savat/
/// qo'ng'iroq tugmalari; Market hero karta; faol buyurtma; yetkazib berish
/// karta; Yangiliklar ro'yxati.
class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final unreadAsync = ref.watch(unreadCountProvider);
    final ordersAsync = ref.watch(myOrdersProvider);
    final newsAsync = ref.watch(newsProvider);

    final cartCount = cartAsync.maybeWhen(
      data: (items) => items.fold<int>(0, (s, it) => s + ((it['quantity'] as int?) ?? 1)),
      orElse: () => 0,
    );
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);
    final activeOrder = ordersAsync.maybeWhen(
      data: (orders) {
        for (final o in orders) {
          final status = o['status'] as String?;
          if (status != null && status != 'delivered' && status != 'cancelled') return o;
        }
        return null;
      },
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: 96.h),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ASSALOMU ALAYKUM 👋', style: AppTextStyles.sectionLabel.copyWith(fontSize: 12)),
                        SizedBox(height: 2.h),
                        Text('Fargonam', style: AppTextStyles.h1.copyWith(color: AppColors.primaryDark, fontSize: 27)),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _IconButtonWithBadge(
                    icon: Icons.shopping_bag_outlined,
                    count: cartCount,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      appShellKey.currentState?.switchTab(0);
                    },
                  ),
                  SizedBox(width: 8.w),
                  _IconButtonWithBadge(
                    icon: Icons.notifications_outlined,
                    count: unread,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    },
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                appShellKey.currentState?.switchTab(0);
              },
              child: Container(
                margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/fergana-gate.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment(0, -0.4),
                  ),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12))],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.25, 0.62, 1],
                            colors: [
                              AppColors.primaryDark.withValues(alpha: 0.8),
                              AppColors.primaryDark.withValues(alpha: 0.4),
                              AppColors.primaryDark.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Market', style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 21)),
                                  SizedBox(height: 5.h),
                                  Text(
                                    'Maktab va ofis uchun kerakli barcha narsalar bir joyda',
                                    style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.78), fontSize: 13, height: 1.45),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 54.w,
                              height: 54.w,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16.r)),
                              child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 27),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(11.r)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Xarid qilishni boshlash', style: AppTextStyles.cardTitleSm.copyWith(color: AppColors.text, fontSize: 13.5)),
                              SizedBox(width: 7.w),
                              Icon(Icons.chevron_right, size: 16.sp, color: AppColors.text),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (activeOrder != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                },
                child: Container(
                  margin: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12.r)),
                        child: Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 19.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${activeOrder['id']} · ${_statusLabel(activeOrder['status'] as String? ?? '')}',
                              style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text('Buyurtmani kuzatish uchun bosing', style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16.sp, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            Container(
              margin: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12.r)),
                    child: Icon(Icons.local_shipping_outlined, color: AppColors.text, size: 18.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yetkazib berish — bepul', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14.5)),
                        SizedBox(height: 2.h),
                        Text('To\'lov yetkazib berishda: naqd yoki karta', style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 12.h),
              child: Text('YANGILIKLAR', style: AppTextStyles.sectionLabel),
            ),
            newsAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: List.generate(
                    2,
                    (_) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Container(
                        height: 72.h,
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18.r)),
                      ),
                    ),
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(children: [for (final n in items) _NewsCard(item: n)]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(String s) => switch (s) {
        'pending' => 'Qabul qilindi',
        'preparing' => 'Tayyorlanmoqda',
        'ready' => 'Tayyor',
        'shipped' => 'Kuryerda',
        'delivered' => 'Yetkazildi',
        'cancelled' => 'Bekor qilingan',
        _ => s,
      };
}

class _IconButtonWithBadge extends StatelessWidget {
  const _IconButtonWithBadge({required this.icon, required this.count, required this.onTap});
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: [const BoxShadow(color: Color(0xFFE8E5E0), blurRadius: 2, offset: Offset(0, 1))],
            ),
            child: Icon(icon, size: 18.sp, color: AppColors.text),
          ),
          if (count > 0)
            Positioned(
              top: -3,
              right: -3,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: AppMotion.pop,
                curve: AppMotion.screenInCurve,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  constraints: BoxConstraints(minWidth: 17.w, minHeight: 17.w),
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$count', style: TextStyle(color: Colors.white, fontSize: 10.5.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final time = _relativeTime(item['created_at'] as String?);
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(13.r)),
            child: Icon(Icons.campaign_outlined, color: AppColors.text, size: 21.sp),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] as String? ?? '',
                        style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14.5, letterSpacing: -0.1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(time, style: AppTextStyles.small.copyWith(fontSize: 11)),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  item['body'] as String? ?? '',
                  style: AppTextStyles.caption.copyWith(fontSize: 12.5, height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relativeTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 24) return 'Bugun';
    if (diff.inDays == 1) return 'Kecha';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return '${dt.day}-${_month(dt.month)}';
  }

  static String _month(int m) => const [
        'yan', 'fev', 'mar', 'apr', 'may', 'iyun', 'iyul', 'avg', 'sen', 'okt', 'noy', 'dek'
      ][m - 1];
}
