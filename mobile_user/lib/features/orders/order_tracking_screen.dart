import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';

const _stages = ['pending', 'preparing', 'ready', 'shipped', 'delivered'];
const _stageTitles = {
  'pending': 'Qabul qilindi',
  'preparing': 'Tayyorlanmoqda',
  'ready': 'Tayyor',
  'shipped': 'Kuryerda',
  'delivered': 'Yetkazildi',
};
const _stageSubs = {
  'pending': 'Buyurtmangiz qabul qilindi',
  'preparing': 'Mahsulotlar yig\'ilmoqda',
  'ready': 'Buyurtma tayyor bo\'ldi',
  'shipped': 'Kuryer yo\'lda',
  'delivered': 'Buyurtma topshirildi',
};

/// Kuzatish — HANDOFF.md 2-bo'lim, 9-band.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final isPickup = order['delivery_type'] == 'pickup';
    final cancelled = status == 'cancelled';
    final idx = _stages.indexOf(isPickup && status == 'shipped' ? 'ready' : status);
    final items = (order['items'] as List? ?? []).cast<Map<String, dynamic>>();
    final total = double.tryParse(order['total']?.toString() ?? '') ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(bottom: 40.h),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FN-${order['id']}', style: AppTextStyles.title),
                      if (order['created_at'] != null) Text(_formatDate(order['created_at'] as String), style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
            ),
            if (isPickup && order['pickup_code'] != null)
              Container(
                margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: AppColors.success.withValues(alpha: 0.35))),
                child: Column(
                  children: [
                    Text('Do\'kondan olib ketish kodi', style: AppTextStyles.caption.copyWith(fontSize: 12)),
                    SizedBox(height: 4.h),
                    Text(order['pickup_code'] as String, style: AppTextStyles.h1.copyWith(color: AppColors.success, letterSpacing: 6, fontSize: 28)),
                  ],
                ),
              ),
            Container(
              margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: cancelled
                  ? Row(
                      children: [
                        Icon(Icons.cancel_outlined, color: AppColors.danger, size: 22.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bekor qilingan', style: AppTextStyles.cardTitle.copyWith(color: AppColors.danger, fontSize: 15)),
                              if ((order['cancel_reason'] as String?)?.isNotEmpty == true)
                                Text(order['cancel_reason'] as String, style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < _stages.length; i++)
                          if (!(isPickup && _stages[i] == 'shipped'))
                            _TimelineStep(
                              title: _stageTitles[_stages[i]]!,
                              sub: _stageSubs[_stages[i]]!,
                              done: i <= idx,
                              isLast: i == _stages.length - 1 || (isPickup && _stages[i + 1] == 'shipped' && i + 1 == _stages.length - 2),
                            ),
                      ],
                    ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  for (final l in items)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: l['product_name'] as String? ?? '', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5)),
                                TextSpan(text: ' × ${l['quantity']}', style: AppTextStyles.caption.copyWith(fontSize: 13)),
                              ]),
                            ),
                          ),
                          Text(formatSom((double.tryParse(l['price_at_purchase']?.toString() ?? '') ?? 0) * (l['quantity'] as int? ?? 0)), style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5)),
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jami', style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
                        Text(formatSom(total), style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = ['yan', 'fev', 'mar', 'apr', 'may', 'iyun', 'iyul', 'avg', 'sen', 'okt', 'noy', 'dek'];
    return '${dt.day}-${months[dt.month - 1]}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.title, required this.sub, required this.done, required this.isLast});
  final String title;
  final String sub;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: done ? AppColors.text : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: done ? AppColors.text : AppColors.border, width: 2),
                ),
                child: done ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
              ),
              if (!isLast) Expanded(child: Container(width: 2, margin: EdgeInsets.symmetric(vertical: 3.h), color: done ? AppColors.text : AppColors.border)),
            ],
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 15, color: done ? AppColors.text : AppColors.textSecondary)),
                  SizedBox(height: 2.h),
                  Text(sub, style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
