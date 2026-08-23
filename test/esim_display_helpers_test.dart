import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/esims/widgets/esim_display_helpers.dart';

void main() {
  group('esimDisplayPackageName', () {
    test('removes provider names from customer-facing labels', () {
      expect(
        esimDisplayPackageName('Orange Balkans 1GB 3 Days'),
        '1 GB 3 Days',
      );
      expect(
        esimDisplayPackageName('[Esim] Europe-41 countries 1GB/30 days'),
        'Europe-41 countries 1 GB · 30 Days',
      );
    });

    test('falls back for an empty package name', () {
      expect(esimDisplayPackageName(''), 'eSIM package');
    });
  });

  group('esimDisplayStatus', () {
    test('converts technical status values into readable labels', () {
      expect(esimDisplayStatus('ready_to_install'), 'Ready to install');
      expect(esimDisplayStatus('NOTACTIVE'), 'Not active');
      expect(esimDisplayStatus('in_progress'), 'In Progress');
    });
  });
}
