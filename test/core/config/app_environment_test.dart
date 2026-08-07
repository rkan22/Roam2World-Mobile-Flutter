import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/config/app_environment.dart';

void main() {
  group('AppEnvironment.isSafeReleaseApiUrl', () {
    test('accepts a public HTTPS endpoint', () {
      expect(
        AppEnvironment.isSafeReleaseApiUrl('https://api.roam2world.com'),
        isTrue,
      );
    });

    test('rejects insecure HTTP endpoints', () {
      expect(
        AppEnvironment.isSafeReleaseApiUrl('http://api.roam2world.com'),
        isFalse,
      );
    });

    test('rejects local development hosts', () {
      const unsafeUrls = <String>[
        'https://localhost:8080',
        'https://127.0.0.1',
        'https://10.0.2.2:8080',
        'https://api.local',
      ];

      for (final url in unsafeUrls) {
        expect(
          AppEnvironment.isSafeReleaseApiUrl(url),
          isFalse,
          reason: '$url must not be accepted in a release build',
        );
      }
    });

    test('rejects malformed or hostless values', () {
      const unsafeValues = <String>[
        '',
        'not-a-url',
        'https://',
      ];

      for (final value in unsafeValues) {
        expect(
          AppEnvironment.isSafeReleaseApiUrl(value),
          isFalse,
          reason: '$value must not be accepted in a release build',
        );
      }
    });
  });
}
