# Fargonam — Production Deploy

Server: `189.74.97.28` (Ubuntu 22.04), foydalanuvchi `fargonam` (sudo, parolsiz SSH
kalit bilan). Loyiha: `/home/fargonam/fargonam` (shu repo, `mobile-ui-rebuild`
branch'idan pull qilinadi). Docker Compose orqali ishga tushadi
(`docker-compose.prod.yml`).

Domenlar:
- `https://api.fargonam.uz` — backend (FastAPI)
- `https://fargonam.uz` — APK yuklab olish sahifasi (statik, `nginx/downloads/`)

## Yangi kodni serverga chiqarish

```bash
ssh fargonam@189.74.97.28
cd ~/fargonam
git pull origin mobile-ui-rebuild

# Faqat backend o'zgargan bo'lsa:
docker compose -f docker-compose.prod.yml up -d --build backend

# nginx.conf yoki docker-compose.prod.yml o'zgargan bo'lsa:
docker compose -f docker-compose.prod.yml up -d --build
```

`nginx/nginx.conf`, `nginx/downloads/*` — bind-mount orqali ulangan, konteynerni
qayta qurmasdan ham darhol ko'rinadi; faqat `nginx -s reload` kifoya bo'lsa:

```bash
docker exec fargonam_nginx nginx -s reload
```

## Loglarni ko'rish

```bash
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f telegram_bot
docker compose -f docker-compose.prod.yml logs --tail 100 nginx
```

## Ma'lumotlar bazasini zaxiralash

```bash
# Zaxira olish
docker exec fargonam_postgres pg_dump -U fargonam fargonam_db | gzip > ~/backups/fargonam_$(date +%F).sql.gz

# Tiklash (ehtiyot bo'ling — mavjud bazani ustiga yozadi)
gunzip -c ~/backups/fargonam_YYYY-MM-DD.sql.gz | docker exec -i fargonam_postgres psql -U fargonam fargonam_db
```

`~/backups/` papkasi mavjud emas bo'lsa avval yarating (`mkdir -p ~/backups`).
Muntazam zaxiralash uchun bu buyruqni cron'ga qo'shish tavsiya etiladi (hozircha
qo'shilmagan).

## APK'larni qayta build qilish

```bash
export PATH="$PATH:$HOME/flutter/bin"
export ANDROID_HOME="$HOME/Android"
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk   # gradle.properties shuni talab qiladi

cd ~/fargonam/mobile_user
flutter build apk --release --dart-define=API_URL=https://api.fargonam.uz
cp build/app/outputs/flutter-apk/app-release.apk \
   ~/fargonam/nginx/downloads/fargonam-user-<versiya>.apk

cd ~/fargonam/mobile_seller
flutter build apk --release --dart-define=API_URL=https://api.fargonam.uz
cp build/app/outputs/flutter-apk/app-release.apk \
   ~/fargonam/nginx/downloads/fargonam-seller-<versiya>.apk
```

Versiya raqami `pubspec.yaml`dagi `version:` qatoridan olinadi (masalan `0.1.0+1`
→ fayl nomida `0.1.0`). Yangi versiya chiqarishda:
1. `mobile_user/pubspec.yaml` va `mobile_seller/pubspec.yaml`da `version:` oshiring.
2. Yuqoridagi build buyruqlarini ishga tushiring.
3. Eski `.apk` fayllarini `nginx/downloads/`dan o'chirib, yangisini qo'ying (yoki
   ikkalasini ham qoldiring — `nginx/downloads/index.html`dagi havolalarni yangi
   fayl nomiga moslab yangilang).
4. Keystore parollari `~/fargonam/mobile_user/android/key.properties` va
   `~/fargonam/mobile_seller/android/key.properties`da (serverda, gitignored) —
   yo'qolsa ilova umuman yangilanmaydi, zaxira nusxasi alohida saqlanadi.

Telegram bot (`fargonam_bot`) `nginx/downloads/`ni o'qiydi — yangi fayl qo'yilishi
bilan `/versiya` va tugmalar avtomatik yangi build'ni topadi, botni qayta ishga
tushirish shart emas.

## Nimadir buzilsa — qayerga qarash

- **Sayt/API ochilmayapti**: `docker ps` — hamma konteyner "Up" holatidami?
  `docker compose -f docker-compose.prod.yml logs nginx` va `logs backend`.
- **HTTPS sertifikat xatosi**: `sudo certbot certificates` — muddati tugaganmi?
  `sudo systemctl status certbot.timer` — avtomatik yangilanish yoqilganmi?
  Qo'lda yangilash: `sudo certbot renew && sudo bash deploy_certs.sh` (sertifikatni
  `nginx/certs/`ga nusxalab, nginx'ni reload qiladi — aniq skript yo'li uchun
  `/etc/letsencrypt/renewal-hooks/deploy/` ichiga qarang).
- **Backend xato beryapti**: `docker logs fargonam_backend --tail 100`. Ko'p hollarda
  `.env` (`~/fargonam/.env`, gitignored) dagi qandaydir qiymat noto'g'ri yoki yo'q —
  kerakli o'zgaruvchilar ro'yxati `backend/app/core/config.py`da.
  `docker exec fargonam_backend env` bilan konteyner ichida qanday qiymat borligini
  tekshiring.
- **Telegram bot javob bermayapti**: `docker logs fargonam_telegram_bot --tail 50`.
  `Conflict: terminated by other getUpdates request` xatosi — shu bot tokeni bilan
  boshqa joyda (boshqa server, lokal skript) getUpdates chaqirilyapti, faqat bitta
  faol bo'lishi mumkin. Token BotFather orqali `/revoke` qilinsa, yangi tokenni
  `~/fargonam/.env`dagi `TELEGRAM_BOT_TOKEN`ga yozib,
  `docker compose -f docker-compose.prod.yml up -d telegram_bot` bilan qayta
  ishga tushiring (kodda token hardcode qilinmagan).
- **Ma'lumotlar bazasi muammosi**: `docker exec -it fargonam_postgres psql -U fargonam fargonam_db`.
  Migratsiya kerak bo'lsa backend konteyneri ishga tushganda avtomatik ishlaydi
  (loglarda "Alembic migratsiyalar ishga tushirilmoqda..." qatorini tekshiring).
- **Disk to'lib qolsa**: `df -h /`, `docker system df`, keraksiz image'larni
  tozalash: `docker image prune -a`.
- **Server umuman javob bermasa**: VPS panel orqali qayta ishga tushiring — barcha
  konteynerlar `restart: always`/`unless-stopped` bilan sozlangan, Docker esa
  `systemctl enable docker` orqali boot'da avtomatik ishga tushadi (2026-08-20'da
  to'liq reboot testi bilan tasdiqlangan).
