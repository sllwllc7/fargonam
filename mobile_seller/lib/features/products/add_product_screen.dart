import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../shop/shop_providers.dart' show myShopProvider;
import 'category_picker.dart';
import 'products_providers.dart';
import 'sku_builder.dart';

/// Yangi mahsulot qo'shish — nom/brend/tavsif/kategoriya + parametrlar orqali
/// avtomatik SKU jadvali (HANDOFF.md 4-bo'lim, 3-band).
///
/// `shopId` berilmasa joriy sotuvchining do'konidan (`myShopProvider`) olinadi
/// — tezkor kirish nuqtalari (masalan Bosh sahifa) uchun qulay.
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, this.shopId});
  final int? shopId;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Category? _category;
  XFile? _pickedImage;
  final List<SkuAttribute> _attributes = [];
  List<SkuRow> _rows = [SkuRow(attrs: const {})];
  bool _loading = false;
  String? _error;

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
      leftover.dispose();
    }
    setState(() => _rows = newRows);
  }

  Future<void> _pickCategory() async {
    HapticFeedback.lightImpact();
    final picked = await showCategoryPicker(context, ref, selectedId: _category?.id);
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final img = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Kamera'),
            onTap: () async => Navigator.pop(ctx, await picker.pickImage(source: ImageSource.camera, imageQuality: 85)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galereya'),
            onTap: () async =>
                Navigator.pop(ctx, await picker.pickImage(source: ImageSource.gallery, imageQuality: 85)),
          ),
        ]),
      ),
    );
    if (img != null) setState(() => _pickedImage = img);
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
    HapticFeedback.mediumImpact();
    if (!_validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _loading = true);
    try {
      var shopId = widget.shopId;
      if (shopId == null) {
        final shop = await ref.read(myShopProvider.future);
        shopId = shop?.id;
      }
      if (shopId == null) throw Exception('Do\'kon topilmadi');

      final first = _rows.first;
      final product = await createProduct(
        ref,
        shopId: shopId,
        categoryId: _category?.id,
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: int.parse(first.priceCtrl.text.trim()),
        stock: int.parse(first.stockCtrl.text.trim()),
      );
      final defaultVariantId = product.variants.isNotEmpty ? product.variants.first.id : null;
      if (defaultVariantId != null && first.attrs.isNotEmpty) {
        await updateProductVariant(
          ref,
          productId: product.id,
          variantId: defaultVariantId,
          variantName: first.label,
          attributes: first.attrs,
        );
      }
      for (var i = 1; i < _rows.length; i++) {
        final r = _rows[i];
        await createProductVariant(
          ref,
          productId: product.id,
          variantName: r.label,
          price: int.parse(r.priceCtrl.text.trim()),
          stock: int.parse(r.stockCtrl.text.trim()),
          attributes: r.attrs,
          sortOrder: i,
        );
      }
      if (_pickedImage != null) {
        await uploadProductImage(ref, productId: product.id, filePath: _pickedImage!.path);
      }
      HapticFeedback.lightImpact();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text('Yangi mahsulot', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180.h,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: _pickedImage != null ? AppColors.sellerAccent : AppColors.border,
                      width: _pickedImage != null ? 1.5 : 1,
                    ),
                  ),
                  child: _pickedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              child: Image.file(File(_pickedImage!.path),
                                  fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _pickedImage = null);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56.w,
                                height: 56.w,
                                decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                                child: Icon(Icons.add_a_photo_outlined, size: 26.sp, color: AppColors.text),
                              ),
                              SizedBox(height: 10.h),
                              Text('Mahsulot rasmini tanlang', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5)),
                              SizedBox(height: 3.h),
                              Text('Kamera yoki galereyadan', style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
                            ],
                          ),
                        ),
                ),
              ),
              SizedBox(height: 18.h),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nomi'),
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _brandCtrl,
                decoration: const InputDecoration(labelText: 'Brend (ixtiyoriy)'),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 12.h),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.input),
                onTap: _pickCategory,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Kategoriya (ixtiyoriy)'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_category?.name ?? 'Tanlanmagan',
                            style: AppTextStyles.body.copyWith(
                                color: _category != null ? AppColors.text : AppColors.textMuted)),
                      ),
                      Icon(Icons.expand_more, color: AppColors.textMuted, size: 20.sp),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Tavsif (ixtiyoriy)'),
                maxLines: 3,
              ),
              SizedBox(height: 22.h),
              AttributesEditor(attributes: _attributes, onChanged: _onAttributesChanged),
              SizedBox(height: 20.h),
              SkuTable(rows: _rows),
              if (_error != null) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                      SizedBox(width: 8.w),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                    ],
                  ),
                ),
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
