import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../products/products_providers.dart';
import 'kit_providers.dart';

class _PickedItem {
  _PickedItem({required this.variantId, required this.label, required this.price, required this.qty});
  final int variantId;
  final String label;
  final int price;
  int qty;
}

/// Sinf to'plami yaratish/tahrirlash — HANDOFF.md 4-bo'lim 5-band: sinf
/// tanlanadi, mahsulotlar ro'yxatdan qo'shiladi, soni belgilanadi, jami avtomatik.
class AddKitScreen extends ConsumerStatefulWidget {
  const AddKitScreen({super.key, required this.shopId, this.editingKit});
  final int shopId;
  final Kit? editingKit;

  @override
  ConsumerState<AddKitScreen> createState() => _AddKitScreenState();
}

class _AddKitScreenState extends ConsumerState<AddKitScreen> {
  late final TextEditingController _nameCtrl;
  String _grade = '1';
  final List<_PickedItem> _items = [];
  bool _loading = false;
  bool _deleting = false;
  String? _error;

  bool get _isEditing => widget.editingKit != null;

  @override
  void initState() {
    super.initState();
    final k = widget.editingKit;
    _nameCtrl = TextEditingController(text: k?.name ?? '1-sinf to\'plami');
    _grade = k?.gradeLevel ?? '1';
    if (k != null) {
      for (final it in k.items) {
        _items.add(_PickedItem(
          variantId: it.variantId,
          label: it.label.isEmpty ? 'Variant #${it.variantId}' : it.label,
          price: it.price ?? 0,
          qty: it.quantity,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  int get _total => _items.fold(0, (s, it) => s + it.price * it.qty);

  Future<void> _pickProduct() async {
    HapticFeedback.lightImpact();
    final productsAsync = ref.read(shopProductsProvider(widget.shopId));
    final products = productsAsync.value ?? [];
    final picked = await showModalBottomSheet<({int variantId, String label, int price})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(products: products),
    );
    if (picked == null) return;
    setState(() {
      _PickedItem? existing;
      for (final it in _items) {
        if (it.variantId == picked.variantId) {
          existing = it;
          break;
        }
      }
      if (existing != null) {
        existing.qty += 1;
      } else {
        _items.add(_PickedItem(variantId: picked.variantId, label: picked.label, price: picked.price, qty: 1));
      }
    });
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nomi kerak');
      return;
    }
    if (_items.isEmpty) {
      setState(() => _error = 'Kamida bitta mahsulot qo\'shing');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final itemsPayload = [for (final it in _items) (variantId: it.variantId, quantity: it.qty)];
      if (_isEditing) {
        await updateKit(
          ref,
          kitId: widget.editingKit!.id,
          shopId: widget.shopId,
          name: _nameCtrl.text.trim(),
          gradeLevel: _grade,
          items: itemsPayload,
        );
      } else {
        await createKit(
          ref,
          shopId: widget.shopId,
          name: _nameCtrl.text.trim(),
          gradeLevel: _grade,
          items: itemsPayload,
        );
      }
      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    HapticFeedback.lightImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('To\'plamni o\'chirish'),
        content: Text('"${widget.editingKit!.name}" ni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting = true);
    try {
      await deleteKit(ref, kitId: widget.editingKit!.id, shopId: widget.shopId);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(_isEditing ? 'To\'plamni tahrirlash' : 'Yangi to\'plam', style: AppTextStyles.title),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _deleting
                  ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _deleting ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sinf', style: AppTextStyles.cardTitleSm),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (var g = 1; g <= 11; g++)
                    _GradeChip(
                      grade: '$g',
                      selected: _grade == '$g',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _grade = '$g';
                          if (_nameCtrl.text.trim().isEmpty || RegExp(r'^\d+-sinf').hasMatch(_nameCtrl.text.trim())) {
                            _nameCtrl.text = '$g-sinf to\'plami';
                          }
                        });
                      },
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nomi'),
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: 22.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mahsulotlar', style: AppTextStyles.cardTitleSm),
                  GestureDetector(
                    onTap: _pickProduct,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.sellerAccentSoft,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 16, color: AppColors.sellerAccent),
                          SizedBox(width: 4.w),
                          Text('Qo\'shish',
                              style: AppTextStyles.small.copyWith(color: AppColors.sellerAccent, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              if (_items.isEmpty)
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(child: Text('Hali mahsulot qo\'shilmagan', style: AppTextStyles.caption)),
                )
              else
                for (var i = 0; i < _items.length; i++) _KitItemRow(item: _items[i], onRemove: () => setState(() => _items.removeAt(i))),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Jami', style: AppTextStyles.cardTitleSm),
                    Text(formatSom(_total), style: AppTextStyles.price.copyWith(fontSize: 17)),
                  ],
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 10.h),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                height: 54.h,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sellerAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Saqlash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.grade, required this.selected, required this.onTap});
  final String grade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.text : AppColors.surfaceAlt,
          shape: BoxShape.circle,
        ),
        child: Text(grade,
            style: AppTextStyles.cardTitleSm.copyWith(color: selected ? Colors.white : AppColors.text, fontSize: 15)),
      ),
    );
  }
}

class _KitItemRow extends StatelessWidget {
  const _KitItemRow({required this.item, required this.onRemove});
  final _PickedItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5)),
                SizedBox(height: 2.h),
                Text(formatSom(item.price), style: AppTextStyles.caption),
              ],
            ),
          ),
          Text('×${item.qty}', style: AppTextStyles.cardTitleSm),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ProductPickerSheet extends StatelessWidget {
  const _ProductPickerSheet({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
                child: Align(alignment: Alignment.centerLeft, child: Text('Mahsulot tanlang', style: AppTextStyles.cardTitle)),
              ),
              Flexible(
                child: products.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.h),
                        child: Center(child: Text('Avval mahsulot qo\'shing', style: AppTextStyles.caption)),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        children: [
                          for (final p in products)
                            for (final v in p.variants)
                              ListTile(
                                onTap: () => Navigator.pop(
                                  context,
                                  (variantId: v.id, label: v.variantName == 'Standart' ? p.name : '${p.name} · ${v.variantName}', price: v.price),
                                ),
                                title: Text(v.variantName == 'Standart' ? p.name : '${p.name} · ${v.variantName}',
                                    style: AppTextStyles.body.copyWith(fontSize: 14)),
                                trailing: Text(formatSom(v.price), style: AppTextStyles.caption),
                              ),
                        ],
                      ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
