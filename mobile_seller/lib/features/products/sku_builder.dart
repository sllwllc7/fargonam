import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bitta parametr (masalan "Varoq soni") + uning qiymatlari (chip: "12","36"...).
class SkuAttribute {
  SkuAttribute({required this.name, List<String>? values}) : values = values ?? [];
  String name;
  List<String> values;
}

/// Bitta SKU qatori — parametr kombinatsiyasi + narx/zaxira.
/// `signature` — kombinatsiyaning barqaror kaliti, attribute tartibi/qiymati
/// o'zgarmasa controller qiymatlari saqlanib qolishi uchun ishlatiladi.
class SkuRow {
  SkuRow({required this.attrs, this.variantId, String? price, String? stock}) {
    priceCtrl = TextEditingController(text: price ?? '');
    stockCtrl = TextEditingController(text: stock ?? '');
  }
  final Map<String, String> attrs;
  final int? variantId; // null = hali backend'da yo'q (yangi qator)
  late final TextEditingController priceCtrl;
  late final TextEditingController stockCtrl;

  String get signature => comboSignature(attrs);
  String get label => attrs.isEmpty ? 'Standart' : attrs.values.join(' · ');

  void dispose() {
    priceCtrl.dispose();
    stockCtrl.dispose();
  }
}

String comboSignature(Map<String, String> c) => c.entries.map((e) => '${e.key}=${e.value}').join('|');

/// Barcha parametr qiymatlarining kartezian ko'paytmasi — har biri bitta SKU.
List<Map<String, String>> cartesianCombos(List<SkuAttribute> attrs) {
  final active = attrs.where((a) => a.name.trim().isNotEmpty && a.values.isNotEmpty).toList();
  if (active.isEmpty) return [const {}];
  List<Map<String, String>> combos = [const {}];
  for (final a in active) {
    final next = <Map<String, String>>[];
    for (final combo in combos) {
      for (final v in a.values) {
        next.add({...combo, a.name.trim(): v});
      }
    }
    combos = next;
  }
  return combos;
}

/// "+ Parametr qo'shish" bo'limi — nom + chip-input qiymatlar ro'yxati.
class AttributesEditor extends StatefulWidget {
  const AttributesEditor({super.key, required this.attributes, required this.onChanged});
  final List<SkuAttribute> attributes;
  final ValueChanged<List<SkuAttribute>> onChanged;

  @override
  State<AttributesEditor> createState() => _AttributesEditorState();
}

class _AttributesEditorState extends State<AttributesEditor> {
  void _addAttribute() {
    HapticFeedback.selectionClick();
    setState(() => widget.attributes.add(SkuAttribute(name: '')));
    widget.onChanged(widget.attributes);
  }

  void _removeAttribute(int i) {
    HapticFeedback.lightImpact();
    setState(() => widget.attributes.removeAt(i));
    widget.onChanged(widget.attributes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Parametrlar', style: AppTextStyles.cardTitleSm),
        SizedBox(height: 4.h),
        Text(
          'Masalan "Varoq soni" — qiymatlari kiritilgach SKU jadvali avtomatik yasaladi',
          style: AppTextStyles.caption,
        ),
        SizedBox(height: 10.h),
        for (int i = 0; i < widget.attributes.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _AttributeRow(
              attribute: widget.attributes[i],
              onChanged: () {
                setState(() {});
                widget.onChanged(widget.attributes);
              },
              onRemove: () => _removeAttribute(i),
            ),
          ),
        GestureDetector(
          onTap: _addAttribute,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.sellerAccent.withValues(alpha: 0.4), style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 18, color: AppColors.sellerAccent),
                SizedBox(width: 6.w),
                Text('Parametr qo\'shish',
                    style: AppTextStyles.cardTitleSm.copyWith(color: AppColors.sellerAccent, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttributeRow extends StatefulWidget {
  const _AttributeRow({required this.attribute, required this.onChanged, required this.onRemove});
  final SkuAttribute attribute;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_AttributeRow> createState() => _AttributeRowState();
}

class _AttributeRowState extends State<_AttributeRow> {
  late final TextEditingController _nameCtrl = TextEditingController(text: widget.attribute.name);
  final _valueCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _addValue(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return;
    if (!widget.attribute.values.contains(v)) {
      setState(() => widget.attribute.values.add(v));
      widget.onChanged();
    }
    _valueCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration.collapsed(hintText: 'Parametr nomi (masalan: Varoq soni)'),
                  style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14),
                  onChanged: (v) {
                    widget.attribute.name = v;
                    widget.onChanged();
                  },
                ),
              ),
              GestureDetector(
                onTap: widget.onRemove,
                child: Icon(Icons.close, size: 18.sp, color: AppColors.textMuted),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final v in widget.attribute.values)
                Chip(
                  label: Text(v, style: AppTextStyles.small.copyWith(color: AppColors.text)),
                  backgroundColor: const Color(0xFFEDE9FE),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => widget.attribute.values.remove(v));
                    widget.onChanged();
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              SizedBox(
                width: 130.w,
                child: TextField(
                  controller: _valueCtrl,
                  decoration: const InputDecoration.collapsed(hintText: 'Qiymat + Enter'),
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  onSubmitted: _addValue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Parametrlar asosida avtomatik yasalgan SKU jadvali — har qatorda narx+zaxira.
class SkuTable extends StatelessWidget {
  const SkuTable({super.key, required this.rows});
  final List<SkuRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SKU jadvali', style: AppTextStyles.cardTitleSm),
        SizedBox(height: 4.h),
        Text('${rows.length} ta kombinatsiya — har biriga narx va zaxira kiriting', style: AppTextStyles.caption),
        SizedBox(height: 10.h),
        for (final row in rows)
          Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5)),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: row.priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Narx (so\'m)', isDense: true),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    SizedBox(
                      width: 96.w,
                      child: TextField(
                        controller: row.stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Zaxira', isDense: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
