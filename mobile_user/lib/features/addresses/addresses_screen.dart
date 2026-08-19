import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_state.dart';

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

const _pinIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M12 21c-4-3.8-6-7-6-9.7a6 6 0 1 1 12 0C18 14 16 17.2 12 21ZM9.8 11.2a2.2 2.2 0 1 0 4.4 0a2.2 2.2 0 1 0-4.4 0" stroke="#000" stroke-width="1.7" stroke-linejoin="round" fill="none"/></svg>';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addrsAsync = ref.watch(addressesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    BackCircleButton(onTap: () => Navigator.maybePop(context)),
                    const SizedBox(width: 12),
                    Text('Manzillarim', style: AppTypography.h2),
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
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                        children: [
                          for (var i = 0; i < addrs.length; i++) ...[
                            FadeUpItem(
                              delay: AppMotion.staggerStep * i,
                              child: _AddressCard(
                                address: addrs[i],
                                onDelete: () => _confirmDelete(context, ref, addrs[i]),
                                onEdit: () => _showEditSheet(context, ref, addrs[i]),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          PressableScale(
                            scale: 0.98,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showAddSheet(context, ref);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppRadius.card),
                                border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.12), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('+', style: AppTypography.cardTitle.copyWith(fontSize: 18, letterSpacing: 0)),
                                  const SizedBox(width: 6),
                                  Text('Yangi manzil qo\'shish', style: AppTypography.rowTitle.copyWith(fontSize: 14)),
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
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> a) async {
    HapticFeedback.lightImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Manzilni o\'chirish'),
        content: Text('"${a['label']}" manzilini o\'chirmoqchimisiz?', style: TextStyle(color: AppColors.textSecondary)),
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
    if (ok == true) {
      HapticFeedback.mediumImpact();
      try {
        await ref.read(dioProvider).delete('/addresses/${a['id']}');
        ref.invalidate(addressesProvider);
      } catch (e) {
        debugPrint('Manzil o\'chirishda xato: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Manzil o\'chirishda xato yuz berdi'), backgroundColor: AppColors.danger, duration: Duration(milliseconds: 1600)),
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

  @override
  Widget build(BuildContext context) {
    final parts = [address['region'], address['district'], address['address']].whereType<String>().where((s) => s.isNotEmpty);
    final fullAddress = parts.join(', ');
    final isDefault = address['is_default'] == true;
    final landmark = address['landmark'] as String?;

    return Dismissible(
      key: ValueKey('addr_${address['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 28),
      ),
      child: GestureDetector(
        onTap: onEdit,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.input)),
                alignment: Alignment.center,
                child: SvgPicture.string(_pinIconSvg, width: 19, height: 19),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(address['label'] as String, style: AppTypography.rowTitle.copyWith(fontSize: 14.5)),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                            child: Text('Asosiy', style: AppTypography.small.copyWith(fontWeight: FontWeight.w800, fontSize: 10.5, color: AppColors.textPrimary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(height: 1.45)),
                    if (landmark != null && landmark.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Mo\'ljal: $landmark', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(fontSize: 12)),
                    ],
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22), onPressed: onDelete),
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
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const ShimmerBox(width: double.infinity, height: 78, borderRadius: AppRadius.card),
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
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text(_isEdit ? 'Manzilni tahrirlash' : 'Yangi manzil', style: AppTypography.h1),
            const SizedBox(height: 20),

            // Tez tanlash chiplari
            Row(
              children: [
                for (final preset in _presets) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectPreset(preset.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _labelCtrl.text == preset.$1 ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                        child: Column(
                          children: [
                            Icon(preset.$2, color: _labelCtrl.text == preset.$1 ? Colors.white : AppColors.textSecondary, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              preset.$1,
                              style: AppTypography.small.copyWith(fontSize: 12, color: _labelCtrl.text == preset.$1 ? Colors.white : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (preset != _presets.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _labelCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Nomi', 'Masalan: Uy, Ish, Universitet', Icons.label_outline),
            ),
            const SizedBox(height: 10),

            // Viloyat + tuman
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _regionCtrl,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: _fieldDecoration('Viloyat', '', Icons.map_outlined),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _district,
                    isExpanded: true,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    dropdownColor: AppColors.surface,
                    decoration: _fieldDecoration('Tuman', '', Icons.location_city_outlined),
                    items: kFerganaDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _district = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _addressCtrl,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Ko\'cha, uy', 'Mahalla, ko\'cha, uy raqami', Icons.location_on_outlined),
              maxLines: 2,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _landmarkCtrl,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration('Mo\'ljal (kuryer uchun)', 'Masalan: ko\'k darvoza yonida', Icons.flag_outlined),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),

            InkWell(
              onTap: () => setState(() => _isDefault = !_isDefault),
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Checkbox(value: _isDefault, activeColor: AppColors.primary, onChanged: (v) => setState(() => _isDefault = v ?? false)),
                    Text('Asosiy manzil qilib belgilash', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(AppRadius.input)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_error!, style: TextStyle(color: AppColors.danger, fontSize: 13))),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Saqlash', loading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint.isEmpty ? null : hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide.none),
    );
  }
}
