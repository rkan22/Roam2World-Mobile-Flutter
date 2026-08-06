# Roam2World Mobile v1 Release Checklist

## Identity and versioning

- [x] Android application ID uses `com.roam2world.mobile`.
- [ ] Confirm the iOS bundle identifier in Xcode.
- [ ] Increment `version` in `pubspec.yaml` for every store upload.
- [ ] Confirm the public app name is `Roam2World` on Android and iOS.

## Android signing

1. Create an upload keystore outside the repository.
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Replace every placeholder with the real upload-key values.
4. Keep the keystore and passwords in the team secret manager.
5. Run `flutter build appbundle --release`.
6. Verify the generated AAB under `build/app/outputs/bundle/release/`.

Never commit `android/key.properties`, `.jks`, or `.keystore` files.

## Quality gates

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build apk --debug`
- [ ] `flutter build appbundle --release`
- [ ] Test login, token refresh, logout, checkout, order creation, eSIM QR, wallet request, and notifications on a physical Android device.
- [ ] Test slow network, offline startup, expired token, and backend error states.

## Store assets and compliance

- [ ] Production launcher icon and adaptive Android icon.
- [ ] Native splash screen.
- [ ] Google Play screenshots and feature graphic.
- [ ] App Store screenshots.
- [ ] Privacy policy URL.
- [ ] Terms of service URL.
- [ ] Complete Play Data safety and App Store privacy declarations.

## Release approval

- [ ] Product owner approves the release candidate.
- [ ] Backend production API and CORS/domain settings are confirmed.
- [ ] Crash reporting and production monitoring are enabled.
- [ ] Create a Git tag after store-ready validation.
