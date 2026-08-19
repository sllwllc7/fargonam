import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';
import '../addresses/addresses_screen.dart' show addressesProvider;
import '../cart/cart_screen.dart' show cartProvider;
import 'order_success_screen.dart';

/// Rasmiylashtirish — HANDOFF.md 2-bo'lim, 7-band.
///
/// Prototipda faqat "Yetkazib berish" bor; real backend "Do'kondan olib
/// ketish" (pickup + kod) ni ham qo'llab-quvvatlaydi — bu ishlaydigan
/// funksiya, olib tashlanmadi, faqat shu uslubda qayta chizildi.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _deliveryType = 'delivery';
  int? _selectedAddressId;
  bool _useFreeText = false;
  bool _initializedDefault = false;
  bool _loading = false;
  String? _idempotencyKey;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canPlace {
    if (_deliveryType == 'pickup') return true;
    return (_selectedAddressId != null && !_useFreeText) || _addressCtrl.text.trim().isNotEmpty;
  }

  Future<void> _placeOrder(List<Map<String, dynamic>> cartItems) async {
    if (!_canPlace) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manzilni kiriting'), backgroundColor: AppColors.danger),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    _idempotencyKey ??= '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    try {
      final useAddressId = !_useFreeText && _selectedAddressId != null;
      final res = await ref.read(dioProvider).post(
        '/orders',
        data: {
          'payment_method': 'cash',
          'delivery_type': _deliveryType,
          if (_deliveryType == 'delivery' && useAddressId) 'delivery_address_id': _selectedAddressId,
          if (_deliveryType == 'delivery' && !useAddressId) 'delivery_address': _addressCtrl.text.trim(),
          if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
        },
        options: Options(headers: {'Idempotency-Key': _idempotencyKey}),
      );
      ref.invalidate(cartProvider);
      _idempotencyKey = null;
      HapticFeedback.heavyImpact();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: res.data as Map<String, dynamic>)));
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['detail']?.toString() ?? 'Xato'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: cartAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) {
            final total = items.fold<double>(0, (s, it) => s + (double.tryParse(it['product_price']?.toString() ?? '') ?? 0) * ((it['quantity'] as int?) ?? 0));

            return Stack(
              children: [
                ListView(
                  padding: EdgeInsets.only(bottom: 130.h),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
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
                          Expanded(
                            child: Text('Rasmiylashtirish', style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                      child: Text('QANDAY OLASIZ?', style: AppTextStyles.sectionLabel),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
                      child: Row(
                        children: [
                          Expanded(child: _DeliveryTypeCard(icon: Icons.local_shipping_outlined, label: 'Yetkazib berish', selected: _deliveryType == 'delivery', onTap: () => setState(() => _deliveryType = 'delivery'))),
                          SizedBox(width: 10.w),
                          Expanded(child: _DeliveryTypeCard(icon: Icons.storefront_outlined, label: 'Do\'kondan olish', selected: _deliveryType == 'pickup', onTap: () => setState(() => _deliveryType = 'pickup'))),
                        ],
                      ),
                    ),
                    if (_deliveryType == 'delivery') ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                        child: Text('YETKAZIB BERISH', style: AppTextStyles.sectionLabel),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: addressesAsync.when(
                          loading: () => Padding(padding: EdgeInsets.all(20.w), child: const LinearProgressIndicator()),
                          error: (_, _) => Padding(padding: EdgeInsets.all(16.w), child: Text('Manzillar yuklanmadi', style: AppTextStyles.caption)),
                          data: (addrs) {
                            if (!_initializedDefault && addrs.isNotEmpty) {
                              _initializedDefault = true;
                              final def = addrs.firstWhere((a) => a['is_default'] == true, orElse: () => addrs.first);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _selectedAddressId = def['id'] as int);
                              });
                            }
                            return Column(
                              children: [
                                for (final a in addrs)
                                  _AddressTile(
                                    address: a,
                                    selected: !_useFreeText && _selectedAddressId == a['id'],
                                    onTap: () => setState(() {
                                      _useFreeText = false;
                                      _selectedAddressId = a['id'] as int;
                                    }),
                                  ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 4.h),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _useFreeText = true),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_location_alt_outlined, size: 16.sp, color: _useFreeText ? AppColors.text : AppColors.textSecondary),
                                        SizedBox(width: 8.w),
                                        Flexible(
                                          child: Text(
                                            'Boshqa manzil kiritish',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.body.copyWith(fontSize: 13.5, color: _useFreeText ? AppColors.text : AppColors.textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_useFreeText || addrs.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 13.h),
                                    child: TextField(
                                      controller: _addressCtrl,
                                      style: AppTextStyles.body.copyWith(color: AppColors.text, fontSize: 14),
                                      decoration: const InputDecoration(hintText: 'Ko\'cha, uy, xonadon', isDense: true),
                                      maxLines: 2,
                                      minLines: 1,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                      child: Text('IZOH', style: AppTextStyles.sectionLabel),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: TextField(
                        controller: _noteCtrl,
                        style: AppTextStyles.body.copyWith(color: AppColors.text, fontSize: 15),
                        decoration: InputDecoration(hintText: 'Kuryer uchun izoh (ixtiyoriy)', hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 15), isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 13.h)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                      child: Text('TO\'LOV', style: AppTextStyles.sectionLabel),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(11.r)),
                            child: Icon(Icons.credit_card, color: AppColors.primaryDark, size: 18.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Yetkazib berishda to\'lash', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14.5)),
                                Text('Naqd yoki karta (POS-terminal)', style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                              ],
                            ),
                          ),
                          Container(
                            width: 22.w,
                            height: 22.w,
                            decoration: const BoxDecoration(color: AppColors.text, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 13),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                      child: Text('BUYURTMA', style: AppTextStyles.sectionLabel),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        children: [
                          for (final l in items)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(children: [
                                        TextSpan(text: l['product_name'] as String? ?? '', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5)),
                                        TextSpan(text: ' × ${l['quantity']}', style: AppTextStyles.caption.copyWith(fontSize: 13)),
                                      ]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    formatSom((double.tryParse(l['product_price']?.toString() ?? '') ?? 0) * (l['quantity'] as int? ?? 0)),
                                    style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 30.h),
                    color: AppColors.bg,
                    child: GestureDetector(
                      onTap: _loading ? null : () => _placeOrder(items),
                      child: Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: _canPlace ? null : AppColors.textMuted,
                          gradient: _canPlace ? AppGradients.primary : null,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text('Buyurtma berish · ${formatSom(total)}', style: AppTextStyles.button, textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeliveryTypeCard extends StatelessWidget {
  const _DeliveryTypeCard({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
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
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: selected ? AppColors.text : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: selected ? AppColors.text : AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22.sp, color: selected ? Colors.white : AppColors.text),
            SizedBox(height: 6.h),
            Text(label, textAlign: TextAlign.center, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13, color: selected ? Colors.white : AppColors.text)),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address, required this.selected, required this.onTap});
  final Map<String, dynamic> address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parts = [address['region'], address['district'], address['address']].whereType<String>().where((s) => s.isNotEmpty);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0D000000)))),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.location_on_outlined, color: selected ? AppColors.text : AppColors.textMuted, size: 18.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address['label'] as String? ?? 'Manzil', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5)),
                  Text(parts.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
