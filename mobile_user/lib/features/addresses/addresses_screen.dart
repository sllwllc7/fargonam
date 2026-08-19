import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_shimmer.dart';

final addressesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/addresses');
  return (res.data as List).cast<Map<String, dynamic>>();
});

/// Farg'ona vodiysi tumanlari — UI qulayligi uchun oldindan to'ldirilgan
/// ro'yxat (backend'da erkin matn, majburiy enum emas).
const kFerganaDistricts = [
  'Farg\'ona shahri',
  'Qo\'qon shahri',
  'Marg\'ilon shahri',
  'Quvasoy shahri',
  'Beshariq tumani',
  'Bog\'dod tumani',
  'Buvayda tumani',
  'Dang\'ara tumani',
  'Furqat tumani',
  'Oltiariq tumani',
  'Quva tumani',
  'Qo\'shtepa tumani',
  'Rishton tumani',
  'So\'x tumani',
  'Toshloq tumani',
  'Uchko\'prik tumani',
  'O\'zbekiston tumani',
  'Yozyovon tumani',
];

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addrsAsync = ref.watch(addressesProvider);
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
                  Text('Manzillarim', style: AppTextStyles.h2.copyWith(fontSize: 23)),
                ],
              ),
            ),
            Expanded(
              child: addrsAsync.when(
                loading: () => const _AddressesSkeleton(),
                error: (e, _) => AppErrorState(error: e, onRetry: () => ref.invalidate(addressesProvider)),
                data: (addrs) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      ref.invalidate(addressesProvider);
                    },
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
                      children: [
                        for (final a in addrs) ...[
                          _AddressCard(
                            address: a,
                            onDelete: () => _confirmDelete(context, ref, a),
                            onEdit: () => _showEditSheet(context, ref, a),
                          ),
                          SizedBox(height: 10.h),
                        ],
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showAddSheet(context, ref);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                              border: Border.all(color: AppColors.text.withValues(alpha: 0.18), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('+', style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
                                SizedBox(width: 6.w),
                                Text('Yangi manzil qo\'shish', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> a) async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Manzilni o\'chirish'),
        content: Text('"${a['label']}" manzilini o\'chirmoqchimisiz?',
            style: TextStyle(color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: isDark ? AppColorsDark.error : AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      try {
        await ref.read(dioProvider).delete('/addresses/${a['id']}');
        ref.invalidate(addressesProvider);
      } catch (e) {
        debugPrint('Manzil o\'chirishda xato: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Manzil o\'chirishda xato yuz berdi'),
              backgroundColor: Colors.red,
              duration: Duration(milliseconds: 1600),
            ),
          );
        }
      }
    }
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAddressSheet(
        onSaved: () {
          ref.invalidate(addressesProvider);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> a) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAddressSheet(
        existing: a,
        onSaved: () {
          ref.invalidate(addressesProvider);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ── Address card ────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onDelete, required this.onEdit});
  final Map<String, dynamic> address;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  IconData get _labelIcon {
    final label = (address['label'] as String).toLowerCase();
    if (label.contains('uy') || label.contains('home')) return Icons.home;
    if (label.contains('ish') || label.contains('work') || label.contains('ofis')) return Icons.work;
    return Icons.location_on;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final error = isDark ? AppColorsDark.error : AppColors.error;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final parts = [address['region'], address['district'], address['address']].whereType<String>().where((s) => s.isNotEmpty);
    final fullAddress = parts.join(', ');
    final isDefault = address['is_default'] == true;

    return Dismissible(
      key: ValueKey('addr_${address['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(color: error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Icon(Icons.delete_outline, color: error, size: 28),
      ),
      child: GestureDetector(
        onTap: onEdit,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: isDefault ? Border.all(color: primary, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(AppRadius.input)),
                child: Icon(_labelIcon, color: Colors.white, size: 22),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(address['label'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp, color: textPrimary)),
                        if (isDefault) ...[
                          SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2.h),
                            decoration: BoxDecoration(color: primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                            child: Text('Asosiy', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: primary)),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textSecondary, fontSize: 13.sp, height: 1.3)),
                    if (address['landmark'] != null && (address['landmark'] as String).isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text('Mo\'ljal: ${address['landmark']}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textSecondary, fontSize: 12.sp)),
                    ],
                  ],
                ),
              ),
              IconButton(icon: Icon(Icons.edit_outlined, color: primary, size: 20), onPressed: onEdit),
              IconButton(icon: Icon(Icons.delete_outline, color: error, size: 22), onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton ────────────────────────────────────────────────

class _AddressesSkeleton extends StatelessWidget {
  const _AddressesSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.lg),
      itemCount: 4,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => AppShimmer(height: 78.h, borderRadius: AppRadius.card),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADD/EDIT ADDRESS SHEET
// ══════════════════════════════════════════════════════════════

class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet({required this.onSaved, this.existing});
  final VoidCallback onSaved;
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _regionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _landmarkCtrl;
  String? _district;
  bool _isDefault = false;
  bool _loading = false;
  String? _error;

  static const _presets = [
    ('Uy', Icons.home),
    ('Ish', Icons.work),
    ('Boshqa', Icons.location_on),
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.existing?['label'] as String? ?? '');
    _regionCtrl = TextEditingController(text: widget.existing?['region'] as String? ?? 'Farg\'ona');
    _addressCtrl = TextEditingController(text: widget.existing?['address'] as String? ?? '');
    _landmarkCtrl = TextEditingController(text: widget.existing?['landmark'] as String? ?? '');
    _district = widget.existing?['district'] as String?;
    _isDefault = widget.existing?['is_default'] == true;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _regionCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(String label) {
    HapticFeedback.selectionClick();
    setState(() => _labelCtrl.text = label);
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    if (_labelCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nomi va manzilni to\'ldiring');
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = {
        'label': _labelCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'region': _regionCtrl.text.trim().isEmpty ? null : _regionCtrl.text.trim(),
        'district': _district,
        'landmark': _landmarkCtrl.text.trim().isEmpty ? null : _landmarkCtrl.text.trim(),
        'is_default': _isDefault,
      };
      if (_isEdit) {
        await ref.read(dioProvider).patch('/addresses/${widget.existing!['id']}', data: data);
      } else {
        await ref.read(dioProvider).post('/addresses', data: data);
      }
      widget.onSaved();
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColorsDark.background : AppColors.background;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final error = isDark ? AppColorsDark.error : AppColors.error;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final h1 = isDark ? AppTextStylesDark.h1 : AppTextStyles.h1;

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(2))),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(_isEdit ? 'Manzilni tahrirlash' : 'Yangi manzil', style: h1),
            SizedBox(height: AppSpacing.lg),

            // Tez tanlash chiplari
            Row(
              children: [
                for (final preset in _presets) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectPreset(preset.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _labelCtrl.text == preset.$1 ? primary : surface,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                        child: Column(
                          children: [
                            Icon(preset.$2, color: _labelCtrl.text == preset.$1 ? Colors.white : textSecondary, size: 22),
                            SizedBox(height: AppSpacing.xs),
                            Text(preset.$1,
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: _labelCtrl.text == preset.$1 ? Colors.white : textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (preset != _presets.last) SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
            SizedBox(height: AppSpacing.md),

            TextField(
              controller: _labelCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: textPrimary),
              decoration: _fieldDecoration('Nomi', 'Masalan: Uy, Ish, Universitet', Icons.label_outline, surface, textSecondary),
            ),
            SizedBox(height: AppSpacing.sm),

            // Viloyat + tuman
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _regionCtrl,
                    style: TextStyle(color: textPrimary),
                    decoration: _fieldDecoration('Viloyat', '', Icons.map_outlined, surface, textSecondary),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _district,
                    isExpanded: true,
                    style: TextStyle(color: textPrimary, fontSize: 14.sp),
                    dropdownColor: surface,
                    decoration: _fieldDecoration('Tuman', '', Icons.location_city_outlined, surface, textSecondary),
                    items: kFerganaDistricts
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _district = v),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),

            TextField(
              controller: _addressCtrl,
              style: TextStyle(color: textPrimary),
              decoration: _fieldDecoration('Ko\'cha, uy', 'Mahalla, ko\'cha, uy raqami', Icons.location_on_outlined, surface, textSecondary),
              maxLines: 2,
            ),
            SizedBox(height: AppSpacing.sm),

            TextField(
              controller: _landmarkCtrl,
              style: TextStyle(color: textPrimary),
              decoration: _fieldDecoration(
                  'Mo\'ljal (kuryer uchun)', 'Masalan: ko\'k darvoza yonida', Icons.flag_outlined, surface, textSecondary),
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: AppSpacing.sm),

            InkWell(
              onTap: () => setState(() => _isDefault = !_isDefault),
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isDefault,
                      activeColor: primary,
                      onChanged: (v) => setState(() => _isDefault = v ?? false),
                    ),
                    Text('Asosiy manzil qilib belgilash', style: TextStyle(color: textPrimary, fontSize: 13.sp)),
                  ],
                ),
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(color: error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.input)),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: error, size: 18),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(_error!, style: TextStyle(color: error, fontSize: 13.sp))),
                          ],
                        ),
                      ),
                    ),
            ),
            SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Saqlash', loading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, String hint, IconData icon, Color fill, Color iconColor) {
    return InputDecoration(
      labelText: label,
      hintText: hint.isEmpty ? null : hint,
      prefixIcon: Icon(icon, color: iconColor),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide.none),
    );
  }
}
