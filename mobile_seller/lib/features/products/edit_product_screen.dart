import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import 'category_picker.dart';
import 'products_providers.dart';
import 'sku_builder.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  const EditProductScreen({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _descCtrl;
  XFile? _newImage;
  int? _categoryId;
  String? _categoryName;
  final List<SkuAttribute> _attributes = [];
  late List<SkuRow> _rows;
  final Set<int> _removedVariantIds = {};
  bool _loading = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _brandCtrl = TextEditingController(text: widget.product.brand ?? '');
    _descCtrl = TextEditingController(text: widget.product.description ?? '');
    _categoryId = widget.product.categoryId;

    // Mavjud variantlardan parametr ta'riflarini tiklash (nom -> tartiblangan qiymatlar to'plami)
    final order = <String>[];
    final valuesByAttr = <String, List<String>>{};
    for (final v in widget.product.variants) {
      for (final entry in v.attributes.entries) {
        final key = entry.key;
        final val = entry.value.toString();
        if (!valuesByAttr.containsKey(key)) {
          order.add(key);
          valuesByAttr[key] = [];
        }
        if (!valuesByAttr[key]!.contains(val)) valuesByAttr[key]!.add(val);
      }
    }
    for (final name in order) {
      _attributes.add(SkuAttribute(name: name, values: valuesByAttr[name]));
    }
    _rows = widget.product.variants
        .map((v) => SkuRow(
              attrs: v.attributes.map((k, val) => MapEntry(k, val.toString())),
              variantId: v.id,
              price: v.price.toString(),
              stock: v.stock.toString(),
            ))
        .toList();
    if (_rows.isEmpty) _rows = [SkuRow(attrs: const {})];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _onAttributesChanged(List<SkuAttribute> attrs) {
    final combos = cartesianCombos(attrs);
    final oldBySig = {for (final r in _rows) r.signature: r};
    final newRows = <SkuRow>[];
    for (final combo in combos) {
      final sig = comboSignature(combo);
      final old = oldBySig.remove(sig);
      newRows.add(old ?? SkuRow(attrs: combo));
    }
    for (final leftover in oldBySig.values) {
      if (leftover.variantId != null) _removedVariantIds.add(leftover.variantId!);
      leftover.dispose();
    }
    setState(() => _rows = newRows);
  }

  Future<void> _pickCategory() async {
    HapticFeedback.lightImpact();
    final picked = await showCategoryPicker(context, ref, selectedId: _categoryId);
    if (picked != null) {
      setState(() {
        _categoryId = picked.id;
        _categoryName = picked.name;
      });
    }
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _newImage = img);
  }

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nomi kerak');
      return false;
    }
    for (final r in _rows) {
      final price = int.tryParse(r.priceCtrl.text.trim());
      final stock = int.tryParse(r.stockCtrl.text.trim());
      if (price == null || price <= 0) {
        setState(() => _error = '"${r.label}" uchun narx > 0 bo\'lishi kerak');
        return false;
      }
      if (stock == null || stock < 0) {
        setState(() => _error = '"${r.label}" uchun zaxira >= 0 bo\'lishi kerak');
        return false;
      }
    }
    setState(() => _error = null);
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await updateProductBase(
        ref,
        productId: widget.product.id,
        shopId: widget.product.shopId,
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        categoryId: _categoryId,
      );
      for (final r in _rows) {
        if (r.variantId == null) {
          await createProductVariant(
            ref,
            productId: widget.product.id,
            variantName: r.label,
            price: int.parse(r.priceCtrl.text.trim()),
            stock: int.parse(r.stockCtrl.text.trim()),
            attributes: r.attrs,
          );
        } else {
          await updateProductVariant(
            ref,
            productId: widget.product.id,
            variantId: r.variantId!,
            variantName: r.label,
            price: int.parse(r.priceCtrl.text.trim()),
            stock: int.parse(r.stockCtrl.text.trim()),
            attributes: r.attrs,
          );
        }
      }
      for (final id in _removedVariantIds) {
        await deleteProductVariant(ref, productId: widget.product.id, variantId: id);
      }
      if (_newImage != null) {
        await uploadProductImage(ref, productId: widget.product.id, filePath: _newImage!.path);
      }
      ref.invalidate(shopProductsProvider(widget.product.shopId));
      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteProduct() async {
    HapticFeedback.lightImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Mahsulotni o\'chirish'),
        content: Text('"${widget.product.name}" ni o\'chirmoqchimisiz?'),
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
      await ref.read(dioProvider).delete('/products/${widget.product.id}');
      ref.invalidate(shopProductsProvider(widget.product.shopId));
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail']?.toString() ?? 'O\'chirishda xato'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Tahrirlash', style: AppTypography.title),
        actions: [
          IconButton(
            icon: _deleting
                ? SizedBox(width: 18, height: 18, child: const CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: _deleting ? null : _deleteProduct,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _loading ? null : _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_newImage != null)
                        Image.file(File(_newImage!.path), fit: BoxFit.cover)
                      else if (widget.product.imageUrl != null)
                        Image.network(
                          '${AppConfig.apiBaseUrl}${widget.product.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Icon(Icons.image_not_supported_outlined, size: 36, color: AppColors.textMuted),
                        )
                      else
                        Icon(Icons.image_outlined, size: 44, color: AppColors.textMuted),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Rasmni o\'zgartirish', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nomi'),
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _brandCtrl,
                decoration: const InputDecoration(labelText: 'Brend (ixtiyoriy)'),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.input),
                onTap: _pickCategory,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Kategoriya (ixtiyoriy)'),
                  child: Builder(builder: (context) {
                    String label = _categoryName ?? 'Tanlanmagan';
                    if (_categoryName == null && _categoryId != null) {
                      final cats = ref.watch(categoriesProvider).value;
                      if (cats != null) {
                        for (final c in cats) {
                          if (c.id == _categoryId) {
                            label = c.name;
                            break;
                          }
                        }
                      }
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: Text(label,
                              style: AppTypography.body
                                  .copyWith(color: label == 'Tanlanmagan' ? AppColors.textMuted : AppColors.textPrimary)),
                        ),
                        Icon(Icons.expand_more, color: AppColors.textMuted, size: 20),
                      ],
                    );
                  }),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Tavsif (ixtiyoriy)'),
                maxLines: 3,
              ),
              SizedBox(height: 22),
              AttributesEditor(attributes: _attributes, onChanged: _onAttributesChanged),
              SizedBox(height: 20),
              SkuTable(rows: _rows),
              if (_error != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
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
