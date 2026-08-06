# Roam2World B2B v1 Release Checklist

## Product identity

- App name: `Roam2World B2B`
- Android application ID: `com.roam2world.b2b`
- iOS bundle identifier: `com.roam2world.b2b`
- Version: `1.0.0+1`

## Quality gates

- Dart source parsing passes
- Flutter analyzer passes
- All widget and parser tests pass
- Android debug APK builds successfully
- Signed Android App Bundle builds with the production upload keystore
- iOS archive builds with the App Store distribution profile

## Device validation

- Test login, token refresh and logout
- Test dashboard, packages, checkout and order creation
- Test order history, eSIM list, QR display and activation code copy
- Test wallet, top-up requests and notifications
- Test offline and stale-cache behavior
- Test representative Android phones and iPhones
- Test tablet layouts where supported

## Store preparation

- Final launcher icon and adaptive icon
- Final splash screen
- Google Play screenshots and feature graphic
- App Store screenshots
- Store descriptions and support contact
- Privacy policy and terms links
- Data safety and App Privacy declarations

## Release approval

- Backend production base URL confirmed
- Production account smoke test completed
- Upload keystore and Apple signing assets backed up securely
- Release notes approved
- Product owner approval recorded
