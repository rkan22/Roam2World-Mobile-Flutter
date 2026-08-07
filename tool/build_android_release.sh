#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "android release build failed: $*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file pubspec.yaml
require_file android/key.properties
require_file android/app/build.gradle.kts

for key in storePassword keyPassword keyAlias storeFile; do
  grep -Eq "^${key}=.+$" android/key.properties || \
    fail "android/key.properties is missing ${key}"
done

store_file="$(sed -n 's/^storeFile=//p' android/key.properties | tail -n 1)"
[[ -n "$store_file" ]] || fail 'storeFile is empty'

if [[ "$store_file" = /* ]]; then
  resolved_store_file="$store_file"
else
  resolved_store_file="android/app/$store_file"
fi

[[ -f "$resolved_store_file" ]] || \
  fail "keystore not found at $resolved_store_file"

production_api_url="${PRODUCTION_API_BASE_URL:-https://api.roam2world.com}"
[[ "$production_api_url" == https://* ]] || fail 'production API must use HTTPS'
[[ ! "$production_api_url" =~ (localhost|127\.0\.0\.1|10\.0\.2\.2|\.local)(:|/|$) ]] || \
  fail 'production API cannot target a local host'

flutter pub get
flutter build appbundle --release \
  --dart-define=API_BASE_URL="$production_api_url"

artifact='build/app/outputs/bundle/release/app-release.aab'
[[ -f "$artifact" ]] || fail "expected artifact was not created: $artifact"

sha256sum "$artifact"
echo "Signed Android App Bundle created at $artifact"
