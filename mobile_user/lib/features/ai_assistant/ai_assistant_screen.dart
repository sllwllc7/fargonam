import 'dart:math';

import 'package:fargonam_ui/fargonam_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _sparkleIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M12 3.5c.6 3.8 1.9 5.1 5.7 5.7-3.8.6-5.1 1.9-5.7 5.7-.6-3.8-1.9-5.1-5.7-5.7 3.8-.6 5.1-1.9 5.7-5.7ZM18 15.5c.3 1.9 1 2.6 2.9 2.9-1.9.3-2.6 1-2.9 2.9-.3-1.9-1-2.6-2.9-2.9 1.9-.3 2.6-1 2.9-2.9Z" stroke="#EEF1F6" stroke-width="1.7" stroke-linejoin="round" fill="none"/></svg>';
const _sendIconSvg =
    '<svg viewBox="0 0 24 24"><path d="M4 12 20 4l-4 8 4 8-16-8ZM20 4 9 12" stroke="#EEF1F6" stroke-width="1.7" stroke-linejoin="round" stroke-linecap="round" fill="none"/></svg>';

/// dc.html'da yuborish tugmasi soyasi — `AppShadows.cta`dan farqli (kichikroq
/// blur/offset), bitta joyda ishlatiladi.
const _sendButtonShadow = [BoxShadow(color: Color(0x47101F38), blurRadius: 14, offset: Offset(0, 6))];

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ScreenFadeIn(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(gradient: AppGradients.cta, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: SvgPicture.string(_sparkleIconSvg, width: 19, height: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fargonam AI', style: AppTypography.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                          Row(
                            children: [
                              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text('Onlayn · yordamga tayyor', style: AppTypography.caption.copyWith(height: null, fontSize: 11.5, color: AppColors.textSecondary)),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  itemCount: _messages.length + (_typing ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i < _messages.length) return _MessageBubble(message: _messages[i]);
                    return const _TypingBubble();
                  },
                ),
              ),
              Padding(
                // Suzuvchi tab bar ekran ustida chiziladi (app_shell.dart) — pastdan
                // shuncha bo'shliq qoldirilmasa, input maydoni tab bar ostida
                // ko'rinmay qoladi.
                padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + AppSizes.tabBarHeight + AppSizes.tabBarBottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.chip), border: Border.all(color: AppColors.inputBorder)),
                        child: TextField(
                          controller: _ctrl,
                          style: AppTypography.body.copyWith(height: null, color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Savolingizni yozing...',
                            hintStyle: AppTypography.body.copyWith(height: null, color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          maxLines: 4,
                          minLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    PressableScale(
                      scale: 0.9,
                      onTap: () => _send(),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(gradient: AppGradients.cta, shape: BoxShape.circle, boxShadow: _sendButtonShadow),
                        alignment: Alignment.center,
                        child: SvgPicture.string(_sendIconSvg, width: 18, height: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: isUser ? AppGradients.cta : null,
            color: isUser ? null : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: const [BoxShadow(color: Color(0x0A171327), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Text(message.text, style: AppTypography.body.copyWith(fontSize: 14, color: isUser ? AppColors.ctaText : AppColors.textPrimary)),
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_ctrl.value + i * 0.3) % 1.0;
              final opacity = (sin(phase * pi * 2) + 1) / 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(width: 7, height: 7, decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.3 + opacity * 0.7), shape: BoxShape.circle)),
              );
            }),
          ),
        ),
      ),
    );
  }
}
