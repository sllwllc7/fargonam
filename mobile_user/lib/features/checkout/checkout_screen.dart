import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../../core/push_service.dart';
import '../addresses/addresses_screen.dart' show addressesProvider;
import '../cart/cart_screen.dart' show cartProvider;
import 'order_success_screen.dart';

const _cardIconSvg =
    '<svg viewBox="0 0 20 20"><rect x="2" y="5" width="16" height="11" rx="2" stroke="#000" stroke-width="1.6" fill="none"/><path d="M2 8.5h16" stroke="#000" stroke-width="1.6"/></svg>';
const _checkIconSvg =
    '<svg viewBox="0 0 12 10"><path d="m1 5 3.5 3.5L11 1" stroke="#EEF1F6" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>';

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
      // Push ruxsati shu yerda so'raladi — ilova ochilishida emas (5.4-bo'lim).
      unawaited(ref.read(pushServiceProvider).requestPermissionForFirstOrder());
      if (mounted) {
        pushReplacementAppRoute(context, (_) => OrderSuccessScreen(order: res.data as Map<String, dynamic>));
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: cartAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) {
            final total = items.fold<double>(0, (s, it) => s + (double.tryParse(it['product_price']?.toString() ?? '') ?? 0) * ((it['quantity'] as int?) ?? 0));

            return ScreenFadeIn(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.only(bottom: 132),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            BackCircleButton(onTap: () => Navigator.pop(context)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Rasmiylashtirish', style: AppTypography.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Text('Qanday olasiz?'.toUpperCase(), style: AppTypography.formSectionLabel),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Row(
                          children: [
                            Expanded(child: _DeliveryTypeCard(icon: Icons.local_shipping_outlined, label: 'Yetkazib berish', selected: _deliveryType == 'delivery', onTap: () => setState(() => _deliveryType = 'delivery'))),
                            const SizedBox(width: 10),
                            Expanded(child: _DeliveryTypeCard(icon: Icons.storefront_outlined, label: 'Do\'kondan olish', selected: _deliveryType == 'pickup', onTap: () => setState(() => _deliveryType = 'pickup'))),
                          ],
                        ),
                      ),
                      if (_deliveryType == 'delivery') ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Text('Yetkazib berish'.toUpperCase(), style: AppTypography.formSectionLabel),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.groupedCard),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.card,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: addressesAsync.when(
                            loading: () => const Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator()),
                            error: (_, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Manzillar yuklanmadi', style: AppTypography.caption)),
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
                                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                                    child: GestureDetector(
                                      onTap: () => setState(() => _useFreeText = true),
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_location_alt_outlined, size: 16, color: _useFreeText ? AppColors.textPrimary : AppColors.textSecondary),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Boshqa manzil kiritish',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.body.copyWith(height: null, fontSize: 13.5, color: _useFreeText ? AppColors.textPrimary : AppColors.textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_useFreeText || addrs.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 13),
                                      child: TextField(
                                        controller: _addressCtrl,
                                        style: AppTypography.body.copyWith(height: null, color: AppColors.textPrimary, fontSize: 14),
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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Text('Izoh'.toUpperCase(), style: AppTypography.formSectionLabel),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.groupedCard),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: TextField(
                          controller: _noteCtrl,
                          style: AppTypography.body.copyWith(height: null, color: AppColors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Kuryer uchun izoh (ixtiyoriy)',
                            hintStyle: AppTypography.body.copyWith(height: null, color: AppColors.textMuted, fontSize: 15),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Text('To\'lov'.toUpperCase(), style: AppTypography.formSectionLabel),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.groupedCard),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.pill)),
                              alignment: Alignment.center,
                              child: SvgPicture.string(_cardIconSvg, width: 18, height: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Yetkazib berishda to\'lash', style: AppTypography.rowTitle),
                                  Text('Naqd yoki karta (POS-terminal)', style: AppTypography.caption.copyWith(height: 1, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(color: AppColors.textPrimary, borderRadius: BorderRadius.circular(AppRadius.pill)),
                              alignment: Alignment.center,
                              child: SvgPicture.string(_checkIconSvg, width: 11, height: 9),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Text('Buyurtma'.toUpperCase(), style: AppTypography.formSectionLabel),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.groupedCard),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final l in items)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0D000000)))),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(text: l['product_name'] as String? ?? '', style: AppTypography.rowTitle.copyWith(fontSize: 13.5)),
                                            TextSpan(
                                              text: ' · ${l['variant_name'] ?? ''} × ${l['quantity']}',
                                              style: AppTypography.caption.copyWith(height: null, fontSize: 13.5, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      formatSom((double.tryParse(l['product_price']?.toString() ?? '') ?? 0) * (l['quantity'] as int? ?? 0)),
                                      style: AppTypography.rowTitle.copyWith(fontSize: 13.5),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Jami', style: AppTypography.price.copyWith(fontSize: 15)),
                                  Text(formatSom(total), style: AppTypography.price.copyWith(fontSize: 15)),
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
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0, 0.7, 1],
                          colors: [AppColors.background, AppColors.background, AppColors.background.withValues(alpha: 0)],
                        ),
                      ),
                      child: PressableScale(
                        onTap: _loading ? () {} : () => _placeOrder(items),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: _canPlace ? null : AppColors.textMuted,
                            gradient: _canPlace ? AppGradients.cta : null,
                            borderRadius: BorderRadius.circular(AppRadius.button),
                            boxShadow: AppShadows.cta,
                          ),
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text('Buyurtma berish · ${formatSom(total)}', style: AppTypography.button, textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: selected ? AppColors.textPrimary : AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: selected ? Colors.white : AppColors.textPrimary),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: AppTypography.cardTitleSm.copyWith(fontSize: 13, color: selected ? Colors.white : AppColors.textPrimary)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0D000000)))),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.location_on_outlined, color: selected ? AppColors.textPrimary : AppColors.textMuted, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address['label'] as String? ?? 'Manzil', style: AppTypography.cardTitleSm.copyWith(fontSize: 13.5)),
                  Text(parts.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
