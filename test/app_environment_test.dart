import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/config/app_environment.dart';

void main() {
  group('release API environment', () {
    test('accepts a public HTTPS endpoint', () {
      expect(
        AppEnvironment.isSafeReleaseApiUrl(
          'https://api.roam2world.com',
        ),
        isTrue,
      );
    });

    test('rejects HTTP and local endpoints', () {
      expect(
        AppEnvironment.isSafeReleaseApiUrl(
          'http://api.roam2world.com',
        ),
        isFalse,
      );
      expect(
        AppEnvironment.isSafeReleaseApiUrl('https://localhost:8000'),
        isFalse,
      );
      expect(
        AppEnvironment.isSafeReleaseApiUrl('https://10.0.2.2:8000'),
        isFalse,
      );
      expect(
        AppEnvironment.isSafeReleaseApiUrl('https://backend.local'),
        isFalse,
      );
    });

    test('rejects malformed or empty values', () {
      expect(AppEnvironment.isSafeReleaseApiUrl(''), isFalse);
      expect(AppEnvironment.isSafeReleaseApiUrl('not a url'), isFalse);
    });
  });
}
