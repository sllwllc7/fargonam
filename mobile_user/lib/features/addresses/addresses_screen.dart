import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

final addressesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get('/addresses');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addrsAsync = ref.watch(addressesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Manzillarim'),
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.midnightIndigo,
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddSheet(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Qo\'shish',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: addrsAsync.when(
        loading: () => const _AddressesSkeleton(),
        error: (e, _) => ErrorRetryWidget(
            error: e, onRetry: () => ref.invalidate(addressesProvider)),
        data: (addrs) {
          if (addrs.isEmpty) {
            return _EmptyAddressesState(
                onAdd: () => _showAddSheet(context, ref));
          }
          return RefreshIndicator(
            color: AppColors.cream,
            backgroundColor: AppColors.surfaceHigh,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              ref.invalidate(addressesProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: addrs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = addrs[i];
                return _AddressCard(
                  address: a,
                  onDelete: () => _confirmDelete(context, ref, a),
                  onEdit: () => _showEditSheet(context, ref, a),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Map<String, dynamic> a) async {
    HapticFeedback.lightImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Manzilni o\'chirish'),
        content: Text(
          '"${a['label']}" manzilini o\'chirmoqchimisiz?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Yo\'q'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
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
      } catch (_) {}
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

  void _showEditSheet(
      BuildContext context, WidgetRef ref, Map<String, dynamic> a) {
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

class _AddressCard extends StatefulWidget {
  const _AddressCard({
    required this.address,
    required this.onDelete,
    required this.onEdit,
  });
  final Map<String, dynamic> address;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  State<_AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<_AddressCard> {
  IconData get _labelIcon {
    final label = (widget.address['label'] as String).toLowerCase();
    if (label.contains('uy') || label.contains('home')) {
      return Icons.home;
    }
    if (label.contains('ish') ||
        label.contains('work') ||
        label.contains('ofis')) {
      return Icons.work;
    }
    return Icons.location_on;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('addr_${widget.address['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        widget.onDelete();
        return false; // o'chirish parent tomonidan boshqariladi
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppColors.error, size: 28),
      ),
      child: GestureDetector(
        onTap: widget.onEdit,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_labelIcon,
                    color: AppColors.cream, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.address['label'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.address['address'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.cream, size: 20),
                onPressed: widget.onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 22),
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────

class _EmptyAddressesState extends StatelessWidget {
  const _EmptyAddressesState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.location_off,
                size: 56,
                color: AppColors.cream.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Manzillar yo\'q',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tez-tez boradigan manzillarni\nsaqlab qo\'ying',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Manzil qo\'shish'),
            ),
          ],
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
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: const [
            ShimmerBox(width: 48, height: 48, borderRadius: 14),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 80, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADD ADDRESS SHEET
// ══════════════════════════════════════════════════════════════

class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet({required this.onSaved, this.existing});
  final VoidCallback onSaved;
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_AddAddressSheet> createState() =>
      _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _addressCtrl;
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
    _labelCtrl = TextEditingController(
        text: widget.existing?['label'] as String? ?? '');
    _addressCtrl = TextEditingController(
        text: widget.existing?['address'] as String? ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(String label) {
    HapticFeedback.selectionClick();
    setState(() => _labelCtrl.text = label);
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    if (_labelCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Barcha maydonlarni to\'ldiring');
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
      };
      if (_isEdit) {
        await ref
            .read(dioProvider)
            .patch('/addresses/${widget.existing!['id']}', data: data);
      } else {
        await ref.read(dioProvider).post('/addresses', data: data);
      }
      widget.onSaved();
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() =>
          _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _isEdit ? 'Manzilni tahrirlash' : 'Yangi manzil',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),

          // Tez tanlash chiplari
          Row(
            children: [
              for (final preset in _presets) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectPreset(preset.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _labelCtrl.text == preset.$1
                            ? AppColors.cream.withValues(alpha: 0.15)
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _labelCtrl.text == preset.$1
                              ? AppColors.cream
                              : AppColors.divider,
                          width: _labelCtrl.text == preset.$1 ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(preset.$2,
                              color: _labelCtrl.text == preset.$1
                                  ? AppColors.cream
                                  : AppColors.textSecondary,
                              size: 24),
                          const SizedBox(height: 6),
                          Text(
                            preset.$1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _labelCtrl.text == preset.$1
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
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
          const SizedBox(height: 16),

          TextField(
            controller: _labelCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nomi',
              hintText: 'Masalan: Uy, Ish, Universitet',
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(
              labelText: 'Manzil',
              hintText: 'To\'liq manzilni kiriting',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.midnightIndigo),
                    )
                  : const Text(
                      'Saqlash',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
