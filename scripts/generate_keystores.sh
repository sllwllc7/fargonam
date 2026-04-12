#!/usr/bin/env bash
# Fargonam — Release keystore yaratish skripti
# Bir marta bajaring: play store uchun APK imzolash uchun kerak.
#
# Foydalanish:
#   chmod +x scripts/generate_keystores.sh
#   ./scripts/generate_keystores.sh
#
# Kalit fayllar .gitignore'ga qo'shilgan — HECH QACHON git'ga push qilmang!

set -euo pipefail

KEYSTORES_DIR="keystores"
mkdir -p "$KEYSTORES_DIR"

echo "============================================="
echo "  Fargonam Release Keystore Generator"
echo "============================================="
echo ""

# ── mobile_user keystore ──────────────────────────────────────
USER_KEYSTORE="$KEYSTORES_DIR/fargonam-user-release.jks"
if [ -f "$USER_KEYSTORE" ]; then
  echo "⚠️  $USER_KEYSTORE allaqachon mavjud, o'tkazib yuborildi."
else
  echo "📱 mobile_user uchun keystore yaratilmoqda..."
  keytool -genkey -v \
    -keystore "$USER_KEYSTORE" \
    -alias fargonam-user \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Fargonam, OU=Mobile, O=Fargonam LLC, L=Fergana, ST=Fergana, C=UZ" \
    -storepass "fargonam@user2024" \
    -keypass "fargonam@user2024"
  echo "✅ $USER_KEYSTORE yaratildi."
fi

# ── mobile_seller keystore ────────────────────────────────────
SELLER_KEYSTORE="$KEYSTORES_DIR/fargonam-seller-release.jks"
if [ -f "$SELLER_KEYSTORE" ]; then
  echo "⚠️  $SELLER_KEYSTORE allaqachon mavjud, o'tkazib yuborildi."
else
  echo "📱 mobile_seller uchun keystore yaratilmoqda..."
  keytool -genkey -v \
    -keystore "$SELLER_KEYSTORE" \
    -alias fargonam-seller \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Fargonam Biznes, OU=Mobile, O=Fargonam LLC, L=Fergana, ST=Fergana, C=UZ" \
    -storepass "fargonam@seller2024" \
    -keypass "fargonam@seller2024"
  echo "✅ $SELLER_KEYSTORE yaratildi."
fi

echo ""
echo "============================================="
echo "  Keystore fayllar tayyor!"
echo "============================================="
echo ""
echo "Keydir: $(pwd)/$KEYSTORES_DIR"
echo ""
echo "Keyingi qadam:"
echo "  mobile_user/android/app/build.gradle.kts'ga signing config qo'shing:"
echo ""
cat <<'EOF'
  signingConfigs {
    release {
      storeFile file("../../keystores/fargonam-user-release.jks")
      storePassword "fargonam@user2024"
      keyAlias "fargonam-user"
      keyPassword "fargonam@user2024"
    }
  }
  buildTypes {
    release {
      signingConfig signingConfigs.release
      minifyEnabled true
      proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
    }
  }
EOF
echo ""
echo "  mobile_seller uchun ham xuddi shunday, fargonam-seller ma'lumotlari bilan."
echo ""
echo "⚠️  MUHIM: keystores/ papkasini HECH QACHON git'ga push qilmang!"
echo "   .gitignore'ga qo'shilgan, lekin ehtiyot bo'ling."
