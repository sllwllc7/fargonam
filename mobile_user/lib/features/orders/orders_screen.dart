import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_shimmer.dart';
import '../shell/app_shell.dart' show appShellKey;
import 'order_detail_screen.dart';

final myOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/orders');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final title = isDark ? AppTextStylesDark.title : AppTextStyles.title;

    final ordersAsync = ref.watch(myOrdersProvider);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('Buyurtmalarim', style: title),
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ordersAsync.when(
        loading: () => const _OrdersSkeleton(),
        error: (e, _) => AppErrorState(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
        data: (orders) {
          if (orders.isEmpty) return const _EmptyOrdersState();
          return RefreshIndicator(
            color: primary,
            backgroundColor: background,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(myOrdersProvider);
            },
            child: ListView.separated(
              padding: EdgeInsets.all(AppSpacing.lg),
              itemCount: orders.length,
              separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) => _OrderCard(order: orders[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order});
  final Map<String, dynamic> order;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final o = widget.order;
    final items = (o['items'] as List?) ?? [];
    final status = o['status'] as String;
    final totalStr = o['total']?.toString() ?? '0';
    final total = double.tryParse(totalStr) ?? 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)));
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('#${o['id']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.sp, color: primary)),
                  ),
                  const Spacer(),
                  _StatusBadge(status: status, deliveryType: o['delivery_type'] as String? ?? 'delivery'),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(AppRadius.input)),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${items.length} ta mahsulot', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: textPrimary)),
                        SizedBox(height: 2.h),
                        Text(_formatDate(o['created_at'] as String), style: TextStyle(color: textSecondary, fontSize: 12.sp)),
                      ],
                    ),
                  ),
                  Text(_formatPrice(total), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.deliveryType = 'delivery'});
  final String status;
  final String deliveryType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final success = isDark ? AppColorsDark.success : AppColors.success;
    final error = isDark ? AppColorsDark.error : AppColors.error;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final isPickup = deliveryType == 'pickup';

    final (label, color) = switch (status) {
      'pending' => ('Kutilmoqda', primary),
      'paid' => ('To\'langan', primary),
      'shipped' => (isPickup ? 'Tayyor' : 'Yo\'lda', primary),
      'delivered' => (isPickup ? 'Topshirildi' : 'Yetkazildi', success),
      'cancelled' => ('Bekor', error),
      _ => (status, textSecondary),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => AppShimmer(height: 96.h, borderRadius: AppRadius.card),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.receipt_long,
      title: 'Hali buyurtma yo\'q',
      subtitle: 'Marketplace\'da o\'zingizga kerakli\nmahsulotlarni tanlang',
      action: AppButton(
        label: 'Marketplace\'ga o\'tish',
        icon: Icons.storefront,
        fullWidth: false,
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.popUntil(context, (route) => route.isFirst);
          appShellKey.currentState?.switchTab(0);
        },
      ),
    );
  }
}

String _formatPrice(num value) {
  final intStr = value.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
    buf.write(intStr[i]);
  }
  return '$buf so\'m';
}
