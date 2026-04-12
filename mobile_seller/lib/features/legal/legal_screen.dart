/// Foydalanish shartlari va Maxfiylik siyosati ekrani — Biznes ilova.
import 'package:flutter/material.dart';

import '../../core/theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Qoidalar'),
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Foydalanish shartlari'),
              Tab(text: 'Maxfiylik siyosati'),
            ],
            labelColor: AppColors.cream,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.cream,
          ),
        ),
        body: const TabBarView(
          children: [
            _TermsOfService(),
            _PrivacyPolicy(),
          ],
        ),
      ),
    );
  }
}

class _TermsOfService extends StatelessWidget {
  const _TermsOfService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _LegalTitle('Biznes foydalanish shartlari'),
          _LegalMeta('Oxirgi yangilanish: 2026-yil 1-aprel'),
          SizedBox(height: 20),
          _LegalSection(
            title: '1. Sotuvchi sifatida ro\'yxatdan o\'tish',
            body:
                'Do\'kon ochish uchun haqiqiy ma\'lumotlar bilan ro\'yxatdan o\'tish kerak. '
                'Admin tomonidan tasdiqlangandan so\'ng mahsulot yuklash imkoni ochiladı.',
          ),
          _LegalSection(
            title: '2. Mahsulot qoidalari',
            body:
                '• Mahsulot tavsifi to\'liq va aniq bo\'lishi shart.\n'
                '• Haqiqiy rasm yuklash majburiy.\n'
                '• Narxlar so\'mda ko\'rsatiladi.\n'
                '• Taqiqlangan tovarlar (alkogol, qurol, noqonuniy mahsulotlar) ruhsat etilmaydi.',
          ),
          _LegalSection(
            title: '3. Buyurtmalar va yetkazib berish',
            body:
                'Buyurtma qabul qilingandan keyin 24 soat ichida tasdiqlash shart. '
                'Kechikkan yoki bekor qilingan buyurtmalar hisobga olinadi — '
                'ko\'p bekor qilish hisobni bloklashga olib kelishi mumkin.',
          ),
          _LegalSection(
            title: '4. Komissiya',
            body:
                'Hozircha platforma komissiya olmaydi (MVP bosqich). '
                'Kelajakda komissiya tartibi alohida xabarnoma bilan bildiriladi.',
          ),
          _LegalSection(
            title: '5. Haydovchilar uchun qoidalar',
            body:
                'Haydovchi sifatida ishlash uchun haqiqiy haydovchilik guvohnomasi talab qilinadi. '
                'Xavfsizlik qoidalarini buzish hisobni to\'xtatishga olib keladi.',
          ),
          _LegalSection(
            title: '6. Javobgarlik',
            body:
                'Platforma sotuvchi va xaridor o\'rtasidagi bitim uchun vositachi hisoblanadi. '
                'Mahsulot sifati va yetkazib berish uchun sotuvchi to\'liq javobgar.',
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PrivacyPolicy extends StatelessWidget {
  const _PrivacyPolicy();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _LegalTitle('Maxfiylik siyosati'),
          _LegalMeta('Oxirgi yangilanish: 2026-yil 1-aprel'),
          SizedBox(height: 20),
          _LegalSection(
            title: '1. Yig\'iladigan ma\'lumotlar',
            body:
                '• Telefon raqami va ism.\n'
                '• Do\'kon ma\'lumotlari (nomi, tavsifi).\n'
                '• Mahsulotlar va buyurtma tarixi.\n'
                '• Joylashuv (haydovchilar uchun aktiv safar paytida).',
          ),
          _LegalSection(
            title: '2. Maqsad',
            body:
                'Ma\'lumotlar faqat xizmat ko\'rsatish, buyurtmalarni boshqarish '
                'va platform xavfsizligini ta\'minlash uchun ishlatiladi.',
          ),
          _LegalSection(
            title: '3. Uchinchi tomon',
            body:
                'Ma\'lumotlar uchinchi shaxslarga sotilmaydi. '
                'To\'lov tizimi (Payme, Click) faqat tranzaksiya ma\'lumotlarini oladi.',
          ),
          _LegalSection(
            title: '4. Saqlash muddati',
            body:
                'Hisob o\'chirilgandan 30 kun ichida ma\'lumotlar o\'chiriladi. '
                'Moliyaviy ma\'lumotlar qonun talabi bo\'yicha saqlanadi.',
          ),
          _LegalSection(
            title: '5. Murojaat',
            body: 'Savollar uchun: support@fargonam.uz',
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _LegalTitle extends StatelessWidget {
  const _LegalTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _LegalMeta extends StatelessWidget {
  const _LegalMeta(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
