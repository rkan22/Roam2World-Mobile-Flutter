# Roam2World B2B Release Checklist

## Automated checks

- [x] Android application ID and namespace are `com.roam2world.b2b`.
- [x] iOS bundle identifier is `com.roam2world.b2b`.
- [x] App display name is `Roam2World B2B`.
- [x] Production API URL uses HTTPS and is not a local address.
- [x] Android release builds include internet access.
- [x] Android release signing, minification, and resource shrinking are configured.
- [x] Signing secrets and keystores are ignored and must not be committed.
- [x] Android launcher icon density files exist.
- [x] iOS AppIcon manifest includes the 1024x1024 marketing icon.
- [x] Flutter formatting, analysis, tests, and Android debug build are part of CI.

## Required before an internal store upload

- [ ] Confirm the launcher icons use the final Roam2World B2B artwork on Android and iOS.
- [ ] Confirm the launch screen uses approved brand artwork and background colors.
- [ ] Create and securely store the production Android upload keystore.
- [ ] Configure `android/key.properties` locally or through CI secrets.
- [ ] Build and install a signed release APK/AAB on a physical Android device.
- [ ] Configure the Apple distribution certificate, App Store provisioning profile, and team.
- [ ] Archive and install a TestFlight build on a physical iPhone and iPad.
- [ ] Verify login, dashboard, package purchase, order history, wallet, eSIM details, and logout against production API configuration.
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

- [ ] Latest `main` CI is green.
- [ ] No unresolved P0/P1 defects.
- [ ] Production API smoke test is signed off.
- [ ] Signed Android and iOS artifacts are reproducible.
- [ ] Version name and build number are incremented before each subsequent upload.
