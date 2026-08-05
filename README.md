# Roam2World Mobile

Premium Flutter mobile experience for Roam2World business connectivity operations.

## Current product flows

- onboarding and authentication
- forgot password
- dashboard and quick actions
- package discovery and package details
- checkout and order success
- orders and QR delivery
- eSIM list, usage and activation details
- customer management
- wallet and transaction history
- notifications
- profile, settings and support
- reusable loading, empty and error states

## Development

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

## Continuous integration

Pull requests and pushes to the active development branch run:

- formatting verification
- static analysis
- widget tests
- Android debug APK build

The current UI uses local sample data. Backend authentication, catalog, order, eSIM, wallet and notification APIs are the next integration layer.
