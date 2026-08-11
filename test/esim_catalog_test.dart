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

  test('parses backend-priced renewal option metadata', () {
    final option = MobileRenewalOption.fromJson({
      'provider': 'tgt',
      'display_provider': 'Orange Balkans',
      'operation': 'renew',
      'product_code': 'E-185-ES-AU-eO1-T-30D/60D-20GB',
      'data_gb': 20,
      'validity_days': 30,
      'price': '14.75',
      'currency': 'USD',
      'pricing': {
        'admin_markup_percent': '10.00',
        'reseller_markup_percent': '5.00',
        'dealer_markup_percent': '2.00',
      },
    });

    expect(option.productCode, 'E-185-ES-AU-eO1-T-30D/60D-20GB');
    expect(option.dataGb, 20);
    expect(option.formattedPrice, 'USD 14.75');
    expect(option.adminMarkupPercent, 10);
    expect(option.resellerMarkupPercent, 5);
    expect(option.dealerMarkupPercent, 2);
  });
}
