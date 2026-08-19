import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';

final _newsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/news', queryParameters: {'limit': 20});
  return (res.data['items'] as List).cast<Map<String, dynamic>>();
});

/// Sotuvchi yangilik/e'lon joylashi — HANDOFF.md 4-bo'lim, 6-band.
class SellerNewsScreen extends ConsumerStatefulWidget {
  const SellerNewsScreen({super.key});

  @override
  ConsumerState<SellerNewsScreen> createState() => _SellerNewsScreenState();
}

class _SellerNewsScreenState extends ConsumerState<SellerNewsScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  XFile? _image;
  bool _posting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _post() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Sarlavha va matn kerak');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _posting = true;
      _error = null;
    });
    try {
      String? imageUrl;
      if (_image != null) {
        final dio = ref.read(dioProvider);
        final form = FormData.fromMap({'file': await MultipartFile.fromFile(_image!.path)});
        final res = await dio.post('/news/image', data: form);
        imageUrl = res.data['image_url'] as String?;
      }
      await ref.read(dioProvider).post('/news', data: {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        if (imageUrl != null) 'image_url': imageUrl,
      });
      HapticFeedback.lightImpact();
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _image = null);
      ref.invalidate(_newsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E\'lon joylandi'), backgroundColor: AppColors.success),
        );
      }
    } on DioException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error = e.response?.data['detail']?.toString() ?? 'Xato');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(_newsListProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, title: Text('Yangiliklar', style: AppTextStyles.title)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Yangi e\'lon', style: AppTextStyles.cardTitleSm),
                  SizedBox(height: 10.h),
                  TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Sarlavha')),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: _bodyCtrl,
                    decoration: const InputDecoration(labelText: 'Matn'),
                    maxLines: 4,
                  ),
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 90.h,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.input),
                              child: Image.file(File(_image!.path), fit: BoxFit.cover, width: double.infinity),
                            )
                          : Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.image_outlined, size: 18.sp, color: AppColors.textMuted),
                                  SizedBox(width: 6.w),
                                  Text('Rasm qo\'shish (ixtiyoriy)', style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                    ),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: 8.h),
                    Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ],
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 48.h,
                    child: FilledButton(
                      onPressed: _posting ? null : _post,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sellerAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                      child: _posting
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('E\'lon qilish', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 22.h),
            Text('SO\'NGGI YANGILIKLAR', style: AppTextStyles.sectionLabel),
            SizedBox(height: 10.h),
            newsAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: ShimmerBox(width: double.infinity, height: 60.h, borderRadius: AppRadius.card),
                  ),
                ),
              ),
              error: (_, _) => Text('Yuklanmadi', style: AppTextStyles.caption),
              data: (items) {
                if (items.isEmpty) return Text('Hali yangilik yo\'q', style: AppTextStyles.caption);
                return Column(children: [for (final n in items) _NewsTile(item: n)]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final imgUrl = item['image_url'] != null ? '${AppConfig.apiBaseUrl}${item['image_url']}' : null;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (imgUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.network(imgUrl, width: 44.w, height: 44.w, fit: BoxFit.cover),
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String? ?? '', style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 2.h),
                Text(item['body'] as String? ?? '', style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
