import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import 'order_tracking_screen.dart';

final myOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/orders');
  return (res.data as List).cast<Map<String, dynamic>>();
});

const _statusLabels = {
  'pending': 'Qabul qilindi',
  'preparing': 'Tayyorlanmoqda',
  'ready': 'Tayyor',
  'shipped': 'Kuryerda',
  'delivered': 'Yetkazildi',
  'cancelled': 'Bekor qilingan',
};

/// Buyurtmalar — HANDOFF.md 2-bo'lim, 10-band.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _tab = 'all';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myOrdersProvider);

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
                      if (!Navigator.of(context).canPop()) return;
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                      child: Icon(Icons.arrow_back_ios_new, size: 15.sp, color: AppColors.text),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('Buyurtmalar', style: AppTextStyles.h2.copyWith(fontSize: 23)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
              child: Row(
                children: [
                  _FilterChip(label: 'Barchasi', selected: _tab == 'all', onTap: () => setState(() => _tab = 'all')),
                  SizedBox(width: 6.w),
                  _FilterChip(label: 'Jarayonda', selected: _tab == 'progress', onTap: () => setState(() => _tab = 'progress')),
                  SizedBox(width: 6.w),
                  _FilterChip(label: 'Yetkazilgan', selected: _tab == 'done', onTap: () => setState(() => _tab = 'done')),
                ],
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Yuklab bo\'lmadi', style: AppTextStyles.caption)),
                data: (allOrders) {
                  final orders = allOrders.where((o) {
                    final status = o['status'] as String;
                    if (_tab == 'all') return true;
                    if (_tab == 'done') return status == 'delivered';
                    return status != 'delivered' && status != 'cancelled';
                  }).toList();

                  if (orders.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Buyurtmalar yo\'q', style: AppTextStyles.cardTitle),
                            SizedBox(height: 6.h),
                            Text('Bu bo\'limda hozircha buyurtma yo\'q', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      ref.invalidate(myOrdersProvider);
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, i) => _OrderCard(order: orders[i]),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 9.h),
        decoration: BoxDecoration(color: selected ? AppColors.text : AppColors.surface, borderRadius: BorderRadius.circular(999.r)),
        child: Text(label, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5, color: selected ? Colors.white : AppColors.textSecondary)),
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
    final o = widget.order;
    final items = (o['items'] as List?) ?? [];
    final status = o['status'] as String;
    final total = double.tryParse(o['total']?.toString() ?? '') ?? 0;
    final (bg, fg) = status == 'delivered'
        ? (AppColors.successSoft, AppColors.success)
        : status == 'cancelled'
            ? (AppColors.dangerSoft, AppColors.danger)
            : (const Color(0xFFEDE9FE), AppColors.primaryDark);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: o)));
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('FN-${o['id']}', style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8.r)),
                    child: Text(_statusLabels[status] ?? status, style: AppTextStyles.small.copyWith(color: fg, fontSize: 11.5)),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Text('${_formatDate(o['created_at'] as String?)} · ${items.length} ta mahsulot', style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatSom(total), style: AppTextStyles.cardTitle.copyWith(fontSize: 15.5)),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = ['yan', 'fev', 'mar', 'apr', 'may', 'iyun', 'iyul', 'avg', 'sen', 'okt', 'noy', 'dek'];
    return '${dt.day}-${months[dt.month - 1]}';
  }
}
