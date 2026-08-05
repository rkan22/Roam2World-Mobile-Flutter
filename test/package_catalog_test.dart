import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/packages/package_catalog.dart';

void main() {
  test('parses mobile package catalog response', () {
    final catalog = PackageCatalog.fromResponse({
      'success': true,
      'data': {
        'packages': [
          {
            'id': 'turkey-10gb',
            'name': 'Turkey 10GB 30 Days',
            'provider': 'tgt',
            'display_provider': 'Orange Turkey',
            'destination_label': 'Turkey',
            'destination_key': 'turkey',
            'data_quantity': 10,
            'data_unit': 'GB',
            'package_validity': 30,
            'package_validity_unit': 'Days',
            'final_price': '15.50',
            'currency': 'USD',
            'countries': [
              {'name': 'Turkey', 'code': 'TR'},
            ],
          },
        ],
        'pagination': {'has_more': true},
      },
    });

    expect(catalog.hasMore, isTrue);
    expect(catalog.packages, hasLength(1));
    expect(catalog.packages.first.id, 'turkey-10gb');
    expect(catalog.packages.first.displayProvider, 'Orange Turkey');
    expect(catalog.packages.first.dataLabel, '10 GB');
    expect(catalog.packages.first.formattedPrice, 'USD 15.50');
    expect(catalog.packages.first.countryCode, 'TR');
  });
}
