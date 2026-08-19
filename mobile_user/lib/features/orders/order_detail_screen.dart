import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_cached_image.dart';
import 'orders_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.order});
  final Map<String, dynamic> order;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Map<String, dynamic> order;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    order = Map.from(widget.order);
  }

  Future<void> _cancelOrder() async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.background : AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Buyurtmani bekor qilish'),
        content: Text('Rostdan ham bu buyurtmani bekor qilmoqchimisiz?',
            style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: isDark ? AppColors.error : AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, bekor qilish'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    HapticFeedback.mediumImpact();
    setState(() => _cancelling = true);
    try {
      await ref.read(dioProvider).post('/orders/${order['id']}/cancel');
      setState(() => order['status'] = 'cancelled');
      ref.invalidate(myOrdersProvider);
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Buyurtma bekor qilindi'),
            backgroundColor: isDark ? AppColors.success : AppColors.success,
            duration: const Duration(milliseconds: 1600),
          ),
        );
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: isDark ? AppColors.error : AppColors.error,
            duration: const Duration(milliseconds: 1600),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.background : AppColors.background;
    final surface = isDark ? AppColors.surface : AppColors.surface;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final error = isDark ? AppColors.error : AppColors.error;
    final success = isDark ? AppColors.success : AppColors.success;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondary;
    final title = isDark ? AppTypography.title : AppTypography.title;
    final caption = isDark ? AppTypography.caption : AppTypography.caption;

    final items = (order['items'] as List?) ?? [];
    final status = order['status'] as String;
    final dt = DateTime.tryParse(order['created_at'] as String);
    final date = dt != null
        ? '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
        : '';
    final totalStr = order['total']?.toString() ?? '0';
    final total = double.tryParse(totalStr) ?? 0;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('Buyurtma #${order['id']}', style: title),
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Status holat kartochka ──
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Holat', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: textPrimary)),
                    const Spacer(),
                    Text(date, style: caption),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                if (status == 'cancelled')
                  const _CancelledBadge()
                else
                  _StatusStepper(currentStatus: status, deliveryType: order['delivery_type'] as String? ?? 'delivery'),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),

          if (order['delivery_type'] == 'pickup' && order['pickup_code'] != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: success.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined, color: success, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('Do\'kondan olib ketish kodi',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: textPrimary)),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    order['pickup_code'] as String,
                    style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.w900, color: success, letterSpacing: 6),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
          ] else if (order['delivery_address'] != null) ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppRadius.card)),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: primary, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(order['delivery_address'] as String, style: TextStyle(fontSize: 13.sp, color: textPrimary)),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
          ],

          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: AppSpacing.sm),
            child: Text('MAHSULOTLAR', style: caption.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
          for (final item in items) _OrderItemTile(item: item as Map<String, dynamic>),

          SizedBox(height: AppSpacing.md),

          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Column(
              children: [
                if (items.isNotEmpty) ...[
                  for (final item in items) ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${(item as Map<String, dynamic>)['product_name'] ?? 'Mahsulot'} × ${item['quantity']}',
                              style: TextStyle(color: textSecondary, fontSize: 13.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(_formatPrice(double.tryParse(item['price_at_purchase']?.toString() ?? '0') ?? 0),
                              style: TextStyle(color: textSecondary, fontSize: 13.sp)),
                        ],
                      ),
                    ),
                  ],
                  Divider(height: AppSpacing.xl, color: isDark ? AppColors.border : AppColors.border),
                ],
                Row(
                  children: [
                    Text('Jami:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: textPrimary)),
                    const Spacer(),
                    Text(_formatPrice(total), style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: primary)),
                  ],
                ),
              ],
            ),
          ),

          if (status == 'pending' || status == 'paid') ...[
            SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancelOrder,
                icon: _cancelling
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: error))
                    : Icon(Icons.cancel_outlined, color: error),
                label: Text('Buyurtmani bekor qilish', style: TextStyle(color: error, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: error.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ── Cancelled badge ──

class _CancelledBadge extends StatelessWidget {
  const _CancelledBadge();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final error = isDark ? AppColors.error : AppColors.error;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.input)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined, color: error, size: 22),
          SizedBox(width: AppSpacing.sm),
          Text('Buyurtma bekor qilingan', style: TextStyle(fontWeight: FontWeight.w800, color: error, fontSize: 14.sp)),
        ],
      ),
    );
  }
}

// ── Status stepper ──

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.currentStatus, required this.deliveryType});
  final String currentStatus;
  final String deliveryType;

  List<(String, String, IconData)> get _steps => [
        ('pending', 'Kutilmoqda', Icons.hourglass_empty),
        ('paid', 'To\'langan', Icons.payment),
        deliveryType == 'pickup'
            ? ('shipped', 'Tayyor — kutilmoqda', Icons.storefront)
            : ('shipped', 'Yo\'lda', Icons.local_shipping),
        ('delivered', deliveryType == 'pickup' ? 'Topshirildi' : 'Yetkazildi', Icons.check_circle),
      ];

  int get _currentIndex => _steps.indexWhere((s) => s.$1 == currentStatus).clamp(0, _steps.length - 1);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          _StepRow(icon: _steps[i].$3, label: _steps[i].$2, isCompleted: i <= _currentIndex, isCurrent: i == _currentIndex),
          if (i < _steps.length - 1) _StepLine(isCompleted: i < _currentIndex),
        ],
      ],
    );
  }
}

class _StepRow extends StatefulWidget {
  const _StepRow({required this.icon, required this.label, required this.isCompleted, required this.isCurrent});
  final IconData icon;
  final String label;
  final bool isCompleted;
  final bool isCurrent;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.isCurrent) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StepRow old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isCurrent && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? AppColors.success : AppColors.success;
    final surface = isDark ? AppColors.surface : AppColors.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondary;

    final color = widget.isCompleted ? success : textSecondary;
    return Row(
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final t = widget.isCurrent ? _ctrl.value : 0.0;
            return Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: widget.isCompleted ? success.withValues(alpha: 0.12) : surface,
                shape: BoxShape.circle,
                border: widget.isCurrent ? Border.all(color: success, width: 2.5) : null,
                boxShadow: widget.isCurrent
                    ? [BoxShadow(color: success.withValues(alpha: 0.2 + (0.4 * t)), blurRadius: 14 + (8 * t), spreadRadius: 1 + (2 * t))]
                    : null,
              ),
              child: Icon(widget.icon, size: 18, color: color),
            );
          },
        ),
        SizedBox(width: AppSpacing.md),
        Text(
          widget.label,
          style: TextStyle(
            fontWeight: widget.isCurrent ? FontWeight.w800 : FontWeight.w600,
            color: widget.isCompleted ? textPrimary : textSecondary,
            fontSize: widget.isCurrent ? 15.sp : 14.sp,
          ),
        ),
        if (widget.isCurrent) ...[
          SizedBox(width: AppSpacing.xs),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: success, shape: BoxShape.circle)),
        ],
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.isCompleted});
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? AppColors.success : AppColors.success;
    final border = isDark ? AppColors.border : AppColors.border;
    return Padding(
      padding: EdgeInsets.only(left: 17.w),
      child: Container(width: 2, height: 26.h, color: isCompleted ? success : border),
    );
  }
}

// ── Order item tile ──

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColors.primary;
    final surface = isDark ? AppColors.surface : AppColors.surface;
    final background = isDark ? AppColors.background : AppColors.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondary;

    final name = item['product_name'] as String? ?? 'Mahsulot #${item['product_id']}';
    final imgUrl = item['product_image_url'] as String?;
    final fullImg = imgUrl != null ? '${AppConfig.apiBaseUrl}$imgUrl' : null;
    final qty = item['quantity'] as int;
    final priceStr = item['price_at_purchase']?.toString();
    final price = priceStr != null ? double.tryParse(priceStr) ?? 0 : 0;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: SizedBox(
              width: 56.w,
              height: 56.w,
              child: fullImg != null
                  ? AppCachedImage(url: fullImg, width: 56.w, height: 56.w, borderRadius: 0)
                  : Container(color: background, child: Icon(Icons.image_outlined, color: textSecondary)),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary, fontSize: 14.sp)),
                SizedBox(height: 4.h),
                Text('${_formatPrice(price.toDouble())} × $qty', style: TextStyle(color: textSecondary, fontSize: 12.sp)),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(_formatPrice(price * qty), style: TextStyle(fontWeight: FontWeight.w800, color: primary, fontSize: 14.sp)),
        ],
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
