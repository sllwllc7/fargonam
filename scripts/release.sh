#!/bin/bash
# Fargonam — bitta buyruq bilan yangi versiya chiqarish (serverda ishga tushiriladi).
#
# Nima qiladi: mobile_user va mobile_seller uchun patch versiyasini oshiradi,
# har birini ikkita arxitektura uchun alohida build qiladi (arm64-v8a —
# zamonaviy telefonlar, armeabi-v7a — eski telefonlar; x86_64 chiqarilmaydi,
# real qurilmalarda deyarli hech qachon kerak bo'lmaydi), APK'larni
# nginx/downloads/ga ko'chiradi (eskilarini o'chiradi), yuklab olish
# sahifasidagi havolalarni yangilaydi, backend/app_version.json va
# backend/status.json'ni yangilaydi (konteyner qayta ishga tushirilmaydi —
# ikkalasi ham read-only bind-mount orqali ulangan), so'ng o'zgargan
# pubspec.yaml'larni commit qiladi.
#
# Foydalanish: ./scripts/release.sh "Izoh (o'zbekcha, foydalanuvchiga ko'rinadi)"
set -euo pipefail

NOTES="${1:?Izoh kerak: ./scripts/release.sh \"Izoh matni\"}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export PATH="$PATH:$HOME/flutter/bin"
export ANDROID_HOME="$HOME/Android"
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
API_URL="https://api.fargonam.uz"

bump_version() {
  local pubspec="$1" current name build major minor patch
  current=$(grep '^version:' "$pubspec" | sed 's/version: //')
  name="${current%+*}"
  build="${current#*+}"
  IFS='.' read -r major minor patch <<<"$name"
  sed -i "s/^version: .*/version: $major.$minor.$((patch + 1))+$((build + 1))/" "$pubspec"
  echo "$major.$minor.$((patch + 1)) $((build + 1))"
}

# Bitta arxitektura uchun build qiladi (--split-per-abi ISHLATILMAYDI —
# har arxitektura alohida --target-platform bilan, shu bilan x86_64'ni
# butunlay chiqarib tashlash oson).
build_arch() {
  local app_dir="$1" target_platform="$2"
  (cd "$app_dir" && flutter build apk --release --target-platform "$target_platform" --dart-define=API_URL="$API_URL") >&2
}

release_app() {
  local app_dir="$1" app_id="$2" out_prefix="$3" version_name version_build start_ts end_ts duration
  local arm64_name arm32_name arm64_size arm32_size

  echo "=== $app_id: versiya oshirilmoqda ===" >&2
  read -r version_name version_build <<<"$(bump_version "$app_dir/pubspec.yaml")"
  echo "$app_id -> $version_name+$version_build" >&2

  find nginx/downloads -maxdepth 1 -name "${out_prefix}-arm64-*.apk" -delete
  find nginx/downloads -maxdepth 1 -name "${out_prefix}-arm32-*.apk" -delete

  echo "=== $app_id: arm64-v8a build ===" >&2
  start_ts=$(date +%s)
  build_arch "$app_dir" "android-arm64"
  end_ts=$(date +%s)
  duration=$((end_ts - start_ts))
  arm64_name="${out_prefix}-arm64-${version_name}.apk"
  cp "$app_dir/build/app/outputs/flutter-apk/app-release.apk" "nginx/downloads/$arm64_name"
  arm64_size=$(stat -c%s "nginx/downloads/$arm64_name")

  echo "=== $app_id: armeabi-v7a build ===" >&2
  build_arch "$app_dir" "android-arm"
  arm32_name="${out_prefix}-arm32-${version_name}.apk"
  cp "$app_dir/build/app/outputs/flutter-apk/app-release.apk" "nginx/downloads/$arm32_name"
  arm32_size=$(stat -c%s "nginx/downloads/$arm32_name")

  echo "$version_name|$version_build|$arm64_name|$arm32_name|$arm64_size|$arm32_size|$duration"
}

USER_RESULT=$(release_app mobile_user user fargonam-user)
IFS='|' read -r U_VERSION U_BUILD U_ARM64 U_ARM32 U_ARM64_SIZE U_ARM32_SIZE U_DURATION <<<"$USER_RESULT"

SELLER_RESULT=$(release_app mobile_seller seller fargonam-seller)
IFS='|' read -r S_VERSION S_BUILD S_ARM64 S_ARM32 S_ARM64_SIZE S_ARM32_SIZE S_DURATION <<<"$SELLER_RESULT"

echo "=== yuklab olish sahifasi yangilanmoqda ==="
sed -i \
  -e "s#href=\"/fargonam-user-arm64-[0-9.]*\.apk\"#href=\"/$U_ARM64\"#" \
  -e "s#href=\"/fargonam-user-arm32-[0-9.]*\.apk\"#href=\"/$U_ARM32\"#" \
  -e "s#href=\"/fargonam-seller-arm64-[0-9.]*\.apk\"#href=\"/$S_ARM64\"#" \
  -e "s#href=\"/fargonam-seller-arm32-[0-9.]*\.apk\"#href=\"/$S_ARM32\"#" \
  -e "s#Xaridor: [0-9.]*#Xaridor: $U_VERSION#" \
  -e "s#Sotuvchi: [0-9.]*#Sotuvchi: $S_VERSION#" \
  nginx/downloads/index.html

echo "=== app_version.json yangilanmoqda ==="
python3 - "$U_VERSION" "$U_BUILD" "$U_ARM64" "$S_VERSION" "$S_BUILD" "$S_ARM64" "$NOTES" <<'PYEOF'
import json, sys
u_version, u_build, u_arm64, s_version, s_build, s_arm64, notes = sys.argv[1:8]
# apk_url — ilova ichidagi yangilanish paneli uchun standart havola
# (deyarli barcha zamonaviy qurilmalar arm64). arm32 faqat sayt/bot orqali.
data = {
    "user": {"version": u_version, "build": int(u_build), "apk_url": f"https://fargonam.uz/{u_arm64}", "notes": notes, "force": False},
    "seller": {"version": s_version, "build": int(s_build), "apk_url": f"https://fargonam.uz/{s_arm64}", "notes": notes, "force": False},
}
with open("backend/app_version.json", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF

echo "=== status.json yangilanmoqda ==="
python3 - "$U_VERSION" "$U_BUILD" "$U_DURATION" "$U_ARM64_SIZE" "$U_ARM32_SIZE" "$S_VERSION" "$S_BUILD" "$S_DURATION" "$S_ARM64_SIZE" "$S_ARM32_SIZE" "$NOTES" <<'PYEOF'
import json, sys, datetime
u_version, u_build, u_duration, u_arm64_size, u_arm32_size, s_version, s_build, s_duration, s_arm64_size, s_arm32_size, notes = sys.argv[1:12]
data = {
    "last_release": {
        "notes": notes,
        "at": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
        "user": {
            "version": u_version, "build": int(u_build), "build_seconds": int(u_duration),
            "arm64_bytes": int(u_arm64_size), "arm32_bytes": int(u_arm32_size),
        },
        "seller": {
            "version": s_version, "build": int(s_build), "build_seconds": int(s_duration),
            "arm64_bytes": int(s_arm64_size), "arm32_bytes": int(s_arm32_size),
        },
    }
}
with open("backend/status.json", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF

echo "=== git commit (pubspec.yaml versiyalari) ==="
git add mobile_user/pubspec.yaml mobile_seller/pubspec.yaml
git commit -m "Release: user $U_VERSION+$U_BUILD, seller $S_VERSION+$S_BUILD — $NOTES"

echo ""
echo "TUGADI"
echo "  user:   $U_VERSION+$U_BUILD  arm64 $((U_ARM64_SIZE / 1024 / 1024))MB, arm32 $((U_ARM32_SIZE / 1024 / 1024))MB"
echo "  seller: $S_VERSION+$S_BUILD  arm64 $((S_ARM64_SIZE / 1024 / 1024))MB, arm32 $((S_ARM32_SIZE / 1024 / 1024))MB"
echo "  Sayt, /app/version, /status va bot darhol yangi APK'ni ko'rsatadi —"
echo "  konteyner qayta ishga tushirish shart emas. 'git push' qo'lda bajariladi."
