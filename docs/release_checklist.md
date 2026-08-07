# Roam2World B2B Release Checklist

## Automated checks

- [x] Android application ID and namespace are `com.roam2world.b2b`.
- [x] iOS bundle identifier is `com.roam2world.b2b`.
- [x] App display name is `Roam2World B2B`.
- [x] Production API default is `https://roam2world-panels-backend.onrender.com`.
- [x] Production API URL uses HTTPS and is not a local address.
- [x] Android release builds include internet access.
- [x] Android backups are disabled for sensitive B2B app data.
- [x] Android cleartext HTTP traffic is disabled.
- [x] Android release signing, minification, and resource shrinking are configured.
- [x] Signing secrets and keystores are ignored and must not be committed.
- [x] Android launcher icon density files exist.
- [x] iOS AppIcon manifest includes the 1024x1024 marketing icon.
- [x] Flutter formatting, analysis, tests, and Android production-config debug build are part of CI.
- [x] A signed Android App Bundle build script validates signing inputs and outputs an artifact checksum.
- [x] A production smoke-test runner keeps credentials local and supports explicit opt-in test purchase.

## Required before an internal store upload

- [ ] Confirm the launcher icons use the final Roam2World B2B artwork on Android and iOS.
- [ ] Confirm the launch screen uses approved brand artwork and background colors.
- [ ] Create and securely store the production Android upload keystore.
- [ ] Configure `android/key.properties` locally or through CI secrets.
- [ ] Run `tool/build_android_release.sh` and archive the generated AAB checksum.
- [ ] Build and install a signed release APK/AAB on a physical Android device.
- [ ] Configure the Apple distribution certificate, App Store provisioning profile, and team.
- [ ] Review app and dependency usage for Apple required-reason APIs, then add or update `PrivacyInfo.xcprivacy` with accurate declarations.
- [ ] Archive and install a TestFlight build on a physical iPhone and iPad.
- [ ] Run `TOKEN="ACCESS_TOKEN" bash tool/smoke_test_production.sh` and verify health, provider health, wallet, categories, packages, and orders.
- [ ] With an approved low-risk Worldmove package, run `ALLOW_PURCHASE=true PACKAGE_ID="..." TOKEN="..." bash tool/smoke_test_production.sh` and verify the returned order in the app.
- [ ] Verify login, dashboard, package purchase, order history, wallet, eSIM details/QR-LPA, and logout against production.
- [ ] Verify Light, Dark, and System appearance modes on phone and tablet.
- [ ] Verify offline, expired-session, slow-network, and server-error states.

## Store metadata

- [ ] Final app title, subtitle/short description, and full description.
- [ ] Privacy policy URL and support URL.
- [ ] Contact email and support ownership.
- [ ] App category and age/content rating answers.
- [ ] Data safety/privacy declarations based on actual API and SDK behavior.
- [ ] Android phone/tablet screenshots.
- [ ] iPhone and iPad screenshots.
- [ ] Google Play feature graphic and App Store promotional assets, where used.
- [ ] Release notes for version `1.0.0`.

## Release decision

- [x] Latest `main` CI is green on production API configuration (`Flutter CI #265`).
- [ ] No unresolved P0/P1 defects found during physical-device smoke testing.
- [ ] Production API smoke test is signed off with the real test account.
- [ ] Signed Android and iOS artifacts are reproducible.
- [ ] Version name and build number are incremented before each subsequent upload.

## Remaining external prerequisites

The repository-side release work is complete enough for a release candidate. The remaining checks require credentials or platform assets that must stay outside source control:

1. A test-account access token, generated locally after login, for the authenticated production smoke test.
2. Android upload keystore plus `key.properties` for the signed AAB.
3. Apple Developer distribution certificate/provisioning/team configuration for TestFlight.
4. Final store artwork, screenshots, privacy/support URLs, and store privacy declarations.

Do not commit passwords, access tokens, keystores, signing passwords, Apple certificates, or private keys.
