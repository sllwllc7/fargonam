#!/bin/bash
# Fargonam — bitta buyruq bilan yangi versiya chiqarish (serverda ishga tushiriladi).
#
# Nima qiladi: mobile_user va mobile_seller uchun patch versiyasini oshiradi,
# ikkalasini ham release rejimida build qiladi, APK'larni
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

release_app() {
  local app_dir="$1" app_id="$2" out_prefix="$3" version_name version_build start_ts end_ts duration apk_name

  echo "=== $app_id: versiya oshirilmoqda ===" >&2
  read -r version_name version_build <<<"$(bump_version "$app_dir/pubspec.yaml")"
  echo "$app_id -> $version_name+$version_build" >&2

  echo "=== $app_id: release build ===" >&2
  start_ts=$(date +%s)
  (cd "$app_dir" && flutter build apk --release --dart-define=API_URL="$API_URL") >&2
  end_ts=$(date +%s)
  duration=$((end_ts - start_ts))

  apk_name="${out_prefix}-${version_name}.apk"
  find nginx/downloads -maxdepth 1 -name "${out_prefix}-*.apk" -delete
  cp "$app_dir/build/app/outputs/flutter-apk/app-release.apk" "nginx/downloads/$apk_name"

  echo "$version_name|$version_build|$apk_name|$duration"
}

USER_RESULT=$(release_app mobile_user user fargonam-user)
IFS='|' read -r U_VERSION U_BUILD U_APK U_DURATION <<<"$USER_RESULT"

SELLER_RESULT=$(release_app mobile_seller seller fargonam-seller)
IFS='|' read -r S_VERSION S_BUILD S_APK S_DURATION <<<"$SELLER_RESULT"

echo "=== yuklab olish sahifasi yangilanmoqda ==="
sed -i \
  -e "s#href=\"/fargonam-user-[0-9.]*\.apk\"#href=\"/$U_APK\"#" \
  -e "s#href=\"/fargonam-seller-[0-9.]*\.apk\"#href=\"/$S_APK\"#" \
  -e "s#Xaridor: [0-9.]*#Xaridor: $U_VERSION#" \
  -e "s#Sotuvchi: [0-9.]*#Sotuvchi: $S_VERSION#" \
  nginx/downloads/index.html

echo "=== app_version.json yangilanmoqda ==="
python3 - "$U_VERSION" "$U_BUILD" "$U_APK" "$S_VERSION" "$S_BUILD" "$S_APK" "$NOTES" <<'PYEOF'
import json, sys
u_version, u_build, u_apk, s_version, s_build, s_apk, notes = sys.argv[1:8]
data = {
    "user": {"version": u_version, "build": int(u_build), "apk_url": f"https://fargonam.uz/{u_apk}", "notes": notes, "force": False},
    "seller": {"version": s_version, "build": int(s_build), "apk_url": f"https://fargonam.uz/{s_apk}", "notes": notes, "force": False},
}
with open("backend/app_version.json", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF

echo "=== status.json yangilanmoqda ==="
python3 - "$U_VERSION" "$U_BUILD" "$U_DURATION" "$S_VERSION" "$S_BUILD" "$S_DURATION" "$NOTES" <<'PYEOF'
import json, sys, datetime
u_version, u_build, u_duration, s_version, s_build, s_duration, notes = sys.argv[1:8]
data = {
    "last_release": {
        "notes": notes,
        "at": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
        "user": {"version": u_version, "build": int(u_build), "build_seconds": int(u_duration)},
        "seller": {"version": s_version, "build": int(s_build), "build_seconds": int(s_duration)},
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
echo "  user:   $U_VERSION+$U_BUILD  (${U_DURATION}s)"
echo "  seller: $S_VERSION+$S_BUILD  (${S_DURATION}s)"
echo "  Sayt, /app/version va bot darhol yangi APK'ni ko'rsatadi — konteyner"
echo "  qayta ishga tushirish shart emas. 'git push' qo'lda bajariladi."
