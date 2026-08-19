import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../cart/cart_screen.dart' show cartProvider;
import 'kit_providers.dart';

const _chevronIconSvg =
    '<svg viewBox="0 0 8 14"><path d="M7 1 1 7l6 6" stroke="#000" stroke-width="2" stroke-linecap="round" fill="none"/></svg>';

/// dc.html'da har bir to'plam elementi o'z kategoriyasiga mos ikonka
/// ishlatadi (`icon(catId)`), lekin `KitItem` modelida kategoriya/slug
/// yo'q (5.0: mavjud model o'zgartirilmadi — PROGRESS.md → Backend
/// farqlari). Shu sabab hammasi uchun bitta neytral quti ikonkasi.
const _packageIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M4 10h16v9H4zM4 13h16M9 10V7h6v3" stroke="#000" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';

/// Sinf to'plami — HANDOFF.md 2-bo'lim, 3-band.
class KitDetailScreen extends ConsumerStatefulWidget {
  const KitDetailScreen({super.key, required this.kit});
  final Kit kit;

  @override
  ConsumerState<KitDetailScreen> createState() => _KitDetailScreenState();
}

class _KitDetailScreenState extends ConsumerState<KitDetailScreen> {
  bool _adding = false;

  Future<void> _addKit() async {
    HapticFeedback.lightImpact();
    setState(() => _adding = true);
    try {
      final dio = ref.read(dioProvider);
      for (final item in widget.kit.items) {
        await dio.post('/cart', data: {'variant_id': item.variantId, 'quantity': item.quantity});
      }
      ref.invalidate(cartProvider);
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('To\'plam savatga qo\'shildi'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail']?.toString() ?? 'Xato'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kit;
    final tint = AppColors.categoryTints[(int.tryParse(k.gradeLevel ?? '1') ?? 1) % AppColors.categoryTints.length];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: ScreenFadeIn(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 132),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          _BackButton(onTap: () => Navigator.pop(context)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(k.name, style: AppTypography.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('${k.items.length} xil mahsulot · to\'liq komplekt', style: AppTypography.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: tint[0], borderRadius: BorderRadius.circular(AppRadius.card)),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15)),
                            alignment: Alignment.center,
                            child: Text(k.gradeLevel ?? '?', style: AppTypography.cardTitle.copyWith(fontSize: 22, color: tint[1], letterSpacing: 0)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Do\'kon tomonidan tayyorlangan — hammasi bitta to\'plamda, alohida qidirish shart emas',
                              style: AppTypography.rowTitle.copyWith(fontWeight: FontWeight.w600, fontSize: 13, height: 1.45, color: tint[1]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < k.items.length; i++)
                            FadeUpItem(
                              delay: AppMotion.staggerStep * i,
                              child: _KitItemRow(item: k.items[i], tint: tint),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Jami', style: AppTypography.cardTitle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: 0)),
                                Text(formatSom(k.total), style: AppTypography.cardTitle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: 0)),
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
                    child: _AddKitButton(adding: _adding, total: k.total, onTap: _adding ? null : _addKit),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddKitButton extends StatefulWidget {
  const _AddKitButton({required this.adding, required this.total, required this.onTap});
  final bool adding;
  final int total;
  final VoidCallback? onTap;

  @override
  State<_AddKitButton> createState() => _AddKitButtonState();
}

class _AddKitButtonState extends State<_AddKitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.pressedDuration,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: AppGradients.cta,
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: AppShadows.cta,
          ),
          alignment: Alignment.center,
          child: widget.adding
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text('To\'plamni savatga qo\'shish · ${formatSom(widget.total)}', style: AppTypography.button, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _KitItemRow extends StatelessWidget {
  const _KitItemRow({required this.item, required this.tint});
  final KitItem item;
  final List<Color> tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0D000000)))),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: tint[0], borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: SvgPicture.string(
              _packageIconSvg,
              width: 26,
              height: 26,
              colorFilter: ColorFilter.mode(tint[1], BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName ?? 'Mahsulot', style: AppTypography.rowTitle.copyWith(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                if ((item.variantName ?? '').isNotEmpty)
                  Text(item.variantName!, style: AppTypography.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('× ${item.quantity}', style: AppTypography.rowTitle.copyWith(fontSize: 13.5)),
              Text(formatSom(item.lineTotal ?? 0), style: AppTypography.caption.copyWith(fontSize: 11.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: AppMotion.pressedDuration,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: AppColors.border, blurRadius: 2, offset: const Offset(0, 1))],
          ),
          alignment: Alignment.center,
          child: SvgPicture.string(_chevronIconSvg, width: 9, height: 15),
        ),
      ),
    );
  }
}
