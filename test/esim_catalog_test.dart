import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/esims/esim_catalog.dart';

void main() {
  test('parses mobile eSIM list response', () {
    final catalog = EsimCatalog.fromResponse({
      'success': true,
      'data': {
        'count': 1,
        'esims': [
          {
            'id': 9,
            'iccid': '8944501234567890123',
            'provider': 'tgt',
            'package_name': 'Europe 20GB',
            'customer_name': 'Ada Lovelace',
            'status': 'activated',
            'profile_status': 'installed',
            'activation_code': 'MATCH-001',
            'qr_code': 'LPA:1\$smdp.example\$MATCH-001',
            'expires_at': '2026-09-05T00:00:00Z',
          }
        ],
      },
    });

    expect(catalog.count, 1);
    expect(catalog.esims.single.id, 9);
    expect(catalog.esims.single.packageName, 'Europe 20GB');
    expect(catalog.esims.single.isInstalled, isTrue);
    expect(catalog.esims.single.hasQr, isTrue);
  });
}
