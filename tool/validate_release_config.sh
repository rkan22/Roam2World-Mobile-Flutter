#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "release validation failed: $*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_match() {
  local pattern="$1"
  local file="$2"
  grep -Eq "$pattern" "$file" || fail "expected pattern not found in $file: $pattern"
}

require_file pubspec.yaml
require_file android/app/build.gradle.kts
require_file android/app/src/main/AndroidManifest.xml
require_file ios/Flutter/Release.xcconfig
require_file ios/Runner/Info.plist
require_file ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
require_file lib/core/config/app_environment.dart
require_file .gitignore

for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  require_file "android/app/src/main/res/mipmap-${density}/ic_launcher.png"
done
require_file ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

require_match '^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$' pubspec.yaml
require_match 'applicationId = "com\.roam2world\.b2b"' android/app/build.gradle.kts
require_match 'namespace = "com\.roam2world\.b2b"' android/app/build.gradle.kts
require_match 'create\("release"\)' android/app/build.gradle.kts
require_match 'isMinifyEnabled = true' android/app/build.gradle.kts
require_match 'isShrinkResources = true' android/app/build.gradle.kts
require_match 'android.permission.INTERNET' android/app/src/main/AndroidManifest.xml
require_match 'android:label="Roam2World B2B"' android/app/src/main/AndroidManifest.xml
require_match 'PRODUCT_BUNDLE_IDENTIFIER=com\.roam2world\.b2b' ios/Flutter/Release.xcconfig
require_match '<string>Roam2World B2B</string>' ios/Runner/Info.plist
require_match 'Icon-App-1024x1024@1x\.png' ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
require_match "static const String appName = 'Roam2World B2B';" lib/core/config/app_environment.dart
require_match '^/android/key\.properties$' .gitignore
require_match '^\*\.jks$' .gitignore
require_match '^\*\.keystore$' .gitignore

if git ls-files --error-unmatch android/key.properties >/dev/null 2>&1; then
  fail 'android/key.properties must never be committed'
fi

if git ls-files '*.jks' '*.keystore' | grep -q .; then
  fail 'keystore files must never be committed'
fi

production_api_url="${PRODUCTION_API_BASE_URL:-https://api.roam2world.com}"
[[ "$production_api_url" == https://* ]] || fail 'production API must use HTTPS'
[[ ! "$production_api_url" =~ (localhost|127\.0\.0\.1|10\.0\.2\.2|\.local)(:|/|$) ]] || \
  fail 'production API cannot target a local host'

echo 'Release configuration validation passed.'
