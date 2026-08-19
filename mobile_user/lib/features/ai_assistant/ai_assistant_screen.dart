import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Fargonam AI assistent — HANDOFF.md 2-bo'lim, 12-band. Qoida asosidagi
/// chatbot (kelajakda backend proxy orqali Gemini bilan almashtiriladi —
/// API kaliti hech qachon ilova kodiga qo'yilmaydi).
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Message> _messages = [];
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
      text: 'Assalomu alaykum! Men Fargonam AI yordamchisiman. Mahsulot tanlash, sinf '
          'to\'plamlari yoki buyurtmangiz haqida so\'rashingiz mumkin.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final value = (text ?? _ctrl.text).trim();
    if (value.isEmpty || _typing) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_Message(text: value, isUser: true));
      _ctrl.clear();
      _typing = true;
    });
    _scrollToBottom();

    await Future.delayed(Duration(milliseconds: 400 + Random().nextInt(700)));
    final reply = _generateReply(value);
    if (!mounted) return;
    setState(() {
      _messages.add(_Message(text: reply, isUser: false));
      _typing = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _generateReply(String input) {
    final q = input.toLowerCase();
    if (q.contains('taksi') || q.contains('taxi') || q.contains('mashina')) {
      return 'Taxi chaqirish uchun pastdagi "Taxi" tabini bosing. Hozircha bu bo\'lim "Tez orada" holatida — ishga tushganda sizga xabar beramiz.';
    }
    if (q.contains('sinf') || q.contains('to\'plam') || q.contains('toplam')) {
      return 'Market bo\'limidagi "Sinflar uchun tayyor mahsulotlar" qatoridan o\'z sinfingizga mos to\'plamni tanlashingiz mumkin — hammasi bitta to\'plamda, alohida qidirish shart emas.';
    }
    if (q.contains('buyurtma') || q.contains('order')) {
      return 'Buyurtma berish uchun: Market\'dan mahsulotni tanlang → savatga qo\'shing → "Buyurtmani rasmiylashtirish"ni bosing. Holatini Profil → Buyurtmalarim bo\'limida kuzatishingiz mumkin.';
    }
    if (q.contains('ruchka')) {
      return 'Eng ommabop tanlov — Alfa ruchka. Premium sovg\'a uchun boshqa brendlar ham bor. Ruchka kategoriyasida ko\'plab mahsulot mavjud.';
    }
    if (q.contains('do\'kon') || q.contains('dokon') || q.contains('market') || q.contains('mahsulot')) {
      return 'Market tabida barcha kategoriyalar bor. Qidiruvdan foydalaning yoki kategoriya tanlang. Yoqqan mahsulotni ♥ tugmasi bilan sevimlilarga qo\'shing.';
    }
    if (q.contains('yetkaz') || q.contains('delivery')) {
      return 'Yetkazib berish bepul. To\'lov kuryerga naqd yoki karta orqali. Manzilingizni Profil → Manzillarim bo\'limida saqlab qo\'ying.';
    }
    if (q.contains('sevimli') || q.contains('yoqqan')) {
      return 'Mahsulot ustidagi ♥ tugmasini bosing — sevimlilaringizga qo\'shiladi. Ularni Profil → Sevimlilar bo\'limida ko\'rasiz.';
    }
    if (q.contains('salom') || q.contains('hey')) {
      return 'Va alaykum assalom! Sizga qanday yordam berishim mumkin?';
    }
    if (q.contains('rahmat') || q.contains('tashakkur')) {
      return 'Sog\' bo\'ling! Yana savolingiz bo\'lsa, men shu yerdaman.';
    }
    return 'Bu demo javob — ilova serverga ulangach, AI orqali haqiqiy javoblar shu yerda ko\'rinadi. Hozircha mahsulotlar, sinf to\'plamlari va buyurtmalar haqida so\'rab ko\'ring.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 10.h),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 19),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fargonam AI', style: AppTextStyles.cardTitle.copyWith(fontSize: 17)),
                        Row(
                          children: [
                            Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                            SizedBox(width: 5.w),
                            Text('Onlayn · yordamga tayyor', style: AppTextStyles.small.copyWith(fontSize: 11.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                itemCount: _messages.length + (_typing ? 1 : 0) + (_messages.length <= 1 ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i < _messages.length) return _MessageBubble(message: _messages[i]);
                  if (_typing && i == _messages.length) return const _TypingBubble();
                  return Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _QuickChip(label: '1-sinf uchun nima kerak?', onTap: () => _send('1-sinf uchun nima kerak?')),
                        _QuickChip(label: 'Qaysi ruchka yaxshi?', onTap: () => _send('Qaysi ruchka yaxshi?')),
                        _QuickChip(label: 'Buyurtmam qayerda?', onTap: () => _send('Buyurtmam qayerda?')),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              // Suzuvchi tab bar ekran ustida chiziladi (app_shell.dart) — pastdan
              // shuncha bo'shliq qoldirilmasa, input maydoni tab bar ostida
              // ko'rinmay qoladi.
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h + AppSizes.tabBarHeight + AppSizes.tabBarBottomInset),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(999.r), border: Border.all(color: AppColors.borderStrong)),
                      child: TextField(
                        controller: _ctrl,
                        style: AppTextStyles.body.copyWith(color: AppColors.primaryDark, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Savolingizni yozing...',
                          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        maxLines: 4,
                        minLines: 1,
                      ),
                    ),
                  ),
                  SizedBox(width: 9.w),
                  GestureDetector(
                    onTap: () => _send(),
                    child: Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle, boxShadow: [const BoxShadow(color: Color(0x4D6D28D9), blurRadius: 14, offset: Offset(0, 6))]),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child)),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            gradient: isUser ? AppGradients.primary : null,
            color: isUser ? null : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: const [BoxShadow(color: Color(0x0D171327), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Text(message.text, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, color: isUser ? Colors.white : AppColors.primaryDark)),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColors.border)),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_ctrl.value + i * 0.3) % 1.0;
              final opacity = (sin(phase * pi * 2) + 1) / 2;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: Container(width: 7, height: 7, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.3 + opacity * 0.7), shape: BoxShape.circle)),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(999.r), border: Border.all(color: AppColors.borderStrong)),
        child: Text(label, style: AppTextStyles.cardTitleSm.copyWith(fontSize: 13, color: AppColors.text)),
      ),
    );
  }
}
