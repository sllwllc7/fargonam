/// Foydalanish shartlari va Maxfiylik siyosati ekrani.
/// Play Store uchun majburiy.
import 'package:flutter/material.dart';

import '../../core/theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, this.initialTab = 0});

  /// 0 — Foydalanish shartlari, 1 — Maxfiylik siyosati
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

// ── Foydalanish shartlari ──────────────────────────────────────

class _TermsOfService extends StatelessWidget {
  const _TermsOfService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _LegalTitle('Foydalanish shartlari'),
          _LegalMeta('Oxirgi yangilanish: 2026-yil 1-aprel'),
          SizedBox(height: 20),
          _LegalSection(
            title: '1. Umumiy qoidalar',
            body:
                'Fargonam ilovasidan foydalanish ushbu shartlarni qabul qilishingizni anglatadi. '
                'Agar siz ushbu shartlarga rozi bo\'lmasangiz, ilovadan foydalanmang.\n\n'
                'Fargonam — Farg\'ona vodiysi uchun ko\'p xizmatli raqamsal platforma. '
                'Xizmatlar doirasiga: onlayn bozor (marketplace), taksi xizmati, '
                'yangiliklar tasmasi va AI yordamchi kiradi.',
          ),
          _LegalSection(
            title: '2. Foydalanuvchi majburiyatlari',
            body:
                '• Faqat haqiqiy shaxsiy ma\'lumotlarni kiriting.\n'
                '• Platformani qonunga xilof maqsadlarda ishlatmang.\n'
                '• Boshqa foydalanuvchilar huquqini hurmat qiling.\n'
                '• Soxta sharh yoki baholash qoldirmang.\n'
                '• Platforma orqali noqonuniy tovar savdosi taqiqlanadi.',
          ),
          _LegalSection(
            title: '3. Sotuvchilar uchun qoidalar',
            body:
                'Do\'kon ochish uchun admin tasdig\'i zarur. Sotuvchi quyidagilarga rozi bo\'ladi:\n'
                '• Mahsulot tavsifi aniq va to\'liq bo\'lishi.\n'
                '• Belgilangan narx va sifatga amal qilish.\n'
                '• Buyurtmalarni o\'z vaqtida bajarish.\n'
                'Qoidalarni buzgan sotuvchilar platformadan chetlatilishi mumkin.',
          ),
          _LegalSection(
            title: '4. To\'lov va qaytarish',
            body:
                'To\'lov naqd pul, karta, Payme yoki Click orqali amalga oshiriladi. '
                'Mahsulot sifatiga shikoyat bo\'lsa, 3 kun ichida murojaat qiling. '
                'Qaytarish tartibi sotuvchi va xaridor o\'rtasida hal qilinadi.',
          ),
          _LegalSection(
            title: '5. Taksi xizmati',
            body:
                'Fargonam taksi xizmatini to\'g\'ridan-to\'g\'ri ta\'minlamaydi — '
                'mustaqil haydovchilar platforma orqali xizmat ko\'rsatadi. '
                'Sayohat xavfsizligi uchun har ikki tomon javobgardir.',
          ),
          _LegalSection(
            title: '6. Javobgarlik chegarasi',
            body:
                'Fargonam platforma operatori sifatida foydalanuvchilar o\'rtasidagi '
                'bitimlar uchun to\'liq javobgarlik olmaydi. '
                'Texnik nosozliklar yuzasidan imkon qadar tezroq xizmat tiklash kafil qilinadi.',
          ),
          _LegalSection(
            title: '7. O\'zgartirish huquqi',
            body:
                'Ushbu shartlar oldindan ogohlantirmasdan o\'zgartirilishi mumkin. '
                'Muhim o\'zgarishlar ilovada xabarnoma orqali bildiriladi.',
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Maxfiylik siyosati ─────────────────────────────────────────

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
            title: '1. Qanday ma\'lumot yig\'amiz',
            body:
                '• Telefon raqami (tizimga kirish uchun).\n'
                '• Ism va familiya (ixtiyoriy).\n'
                '• Buyurtma tarixi va manzillar.\n'
                '• Qurilma FCM token (push xabarnomalar uchun).\n'
                '• Joylashuv (taksi xizmatida faqat foydalanish paytida).',
          ),
          _LegalSection(
            title: '2. Ma\'lumotlardan foydalanish maqsadi',
            body:
                '• Xizmat ko\'rsatish va buyurtmalarni amalga oshirish.\n'
                '• Push xabarnomalar yuborish.\n'
                '• Xizmat sifatini oshirish va tahlil qilish.\n'
                '• Qonun talablariga rioya qilish.',
          ),
          _LegalSection(
            title: '3. Ma\'lumotlarni uchinchi tomonga berish',
            body:
                'Ma\'lumotlaringiz uchinchi shaxslarga sotilmaydi. '
                'Faqat xizmat ko\'rsatuvchi sheriklar (SMS, to\'lov tizimi) '
                'zaruriy minimal ma\'lumotlarga ega bo\'lishi mumkin.',
          ),
          _LegalSection(
            title: '4. Ma\'lumotlarni saqlash muddati',
            body:
                'Hisob o\'chirilgandan so\'ng 30 kun ichida shaxsiy ma\'lumotlar '
                'tizimdan o\'chiriladi. Soliqqa oid ma\'lumotlar qonun talab qilgan '
                'muddatda saqlanadi.',
          ),
          _LegalSection(
            title: '5. Xavfsizlik',
            body:
                'Ma\'lumotlar shifrlangan serverda saqlanadi. '
                'HTTPS protokoli va JWT autentifikatsiya ishlatiladi. '
                'Parol o\'rniga OTP (bir martalik kod) orqali kirish ta\'minlangan.',
          ),
          _LegalSection(
            title: '6. Foydalanuvchi huquqlari',
            body:
                '• O\'z ma\'lumotlaringizni ko\'rish va tahrirlash.\n'
                '• Hisobni o\'chirish.\n'
                '• Ma\'lumotlarni eksport qilish.\n\n'
                'Murojaat uchun: support@fargonam.uz',
          ),
          _LegalSection(
            title: '7. Cookie va kuzatuv',
            body:
                'Mobil ilova cookie ishlatmaydi. '
                'Faqat ilovaning ishlashi uchun zarur bo\'lgan local storage va secure storage ishlatiladi.',
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Yordamchi widgetlar ────────────────────────────────────────

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
