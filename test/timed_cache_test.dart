import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/cache/timed_cache.dart';

void main() {
  test('returns a stored value before the ttl expires', () {
    final cache = TimedCache<String>(ttl: const Duration(minutes: 1));

    cache.set('dashboard');

    expect(cache.value, 'dashboard');
  });

  test('clear removes the stored value', () {
    final cache = TimedCache<int>(ttl: const Duration(minutes: 1));

    cache.set(42);
    cache.clear();

    expect(cache.value, isNull);
  });

  test('expired values are removed', () async {
    final cache = TimedCache<String>(ttl: Duration.zero);

    cache.set('stale');
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(cache.value, isNull);
  });
}
