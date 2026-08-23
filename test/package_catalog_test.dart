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
            'is_price_visible': true,
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

  test('hides package price unless backend explicitly allows it', () {
    final package = MobilePackage.fromJson({
      'id': 'unpriced-package',
      'name': 'Unpriced Package',
      'provider': 'flexnet',
      'price': '39.99',
      'is_price_visible': false,
    });

    expect(package.isPriceAvailable, isFalse);
    expect(package.formattedPrice, 'Contact Admin');
  });

  test('parses and classifies Worldmove unified catalog packages', () {
    final catalog = PackageCatalog.fromWorldmoveResponse({
      'success': true,
      'packages': [
        {
          'id': 'WM-E-J1-VDFES-XL',
          'provider': 'worldmove',
          'productName': 'Vodafone Travel XL',
          'productRegion': 'Europe',
          'package_type': 'ESIM',
          'is_esim': true,
          'price': '42.50',
        },
        {
          'id': 'WM-TR-10GB-30D',
          'provider': 'worldmove',
          'name': 'Turkey 10GB 30 Days',
          'productRegion': 'Turkey',
          'package_type': 'SIMCARD',
          'is_esim': false,
          'price': '12.00',
        },
      ],
    });

    expect(catalog.packages, hasLength(2));
    expect(catalog.packages.first.displayProvider, 'Vodafone');
    expect(catalog.packages.first.operatorKey, 'vodafone');
    expect(catalog.packages.first.destinationKey, 'europe');
    expect(catalog.packages.first.dataLabel, '45 GB');
    expect(catalog.packages.first.validityLabel, '30 Days');
    expect(catalog.packages.first.packageType, 'esim');
    expect(catalog.packages.last.displayProvider, 'T.T Turkey');
    expect(catalog.packages.last.operatorKey, 'turkey');
    expect(catalog.packages.last.destinationKey, 'turkey');
    expect(catalog.packages.last.packageType, 'simcard');
  });

  test('accepts a nested Worldmove package list', () {
    final catalog = PackageCatalog.fromWorldmoveResponse({
      'data': {
        'packages': [
          {
            'id': 'WM-E-J1-O-T20',
            'provider': 'worldmove',
            'name': 'Orange Europe 20GB',
            'price': '12.00',
          },
        ],
      },
    });

    expect(catalog.packages.single.id, 'WM-E-J1-O-T20');
  });

  test('normalizes manual fulfillment catalog products', () {
    final catalog = PackageCatalog.fromManualResponse({
      'success': true,
      'data': [
        {
          'id': 'database-row-id',
          'package_id': 'MANUAL-VDF-600',
          'operator_name': 'Vodafone',
          'product_name': 'Vodafone 600GB',
          'product_type': 'sim',
          'data_gb': '600',
          'validity_days': 30,
          'coverage_countries': ['Europe'],
          'base_price': '25.00',
          'currency': 'USD',
        },
      ],
    });

    final package = catalog.packages.single;
    expect(package.id, 'MANUAL-VDF-600');
    expect(package.provider, 'manual');
    expect(package.displayProvider, 'Vodafone');
    expect(package.destinationKey, 'europe');
    expect(package.packageType, 'simcard');
    expect(package.dataLabel, '600 GB');
  });

  test('classifies Worldmove physical SIM and exposes filter values', () {
    final catalog = PackageCatalog.fromWorldmoveResponse({
      'packages': [
        {
          'id': 'WM-EU-B-30D-20GB',
          'provider': 'worldmove',
          'productName': 'KPN Europe 20GB',
          'productRegion': 'Europe',
          'price': '18.00',
        },
      ],
    });

    final package = catalog.packages.single;
    expect(package.packageType, 'simcard');
    expect(package.dataGb, 20);
    expect(package.validityDays, 30);
  });

  test('normalizes a direct provider catalog response', () {
    final catalog = PackageCatalog.fromProviderResponse(
      {
        'data': {
          'packages': [
            {
              'planCode': 'AIR-EU-200',
              'planName': 'Europe 200GB',
              'dataAmount': 200,
              'validityDays': 30,
              'destination': 'Europe',
              'price': '20.00',
            },
          ],
        },
      },
      provider: 'airhub',
      displayProvider: 'Vodafone',
    );

    final package = catalog.packages.single;
    expect(package.id, 'AIR-EU-200');
    expect(package.name, 'Vodafone 200GB 30 Days');
    expect(package.displayProvider, 'Vodafone');
    expect(package.dataLabel, '200 GB');
    expect(package.validityLabel, '30 Days');
    expect(package.destinationKey, 'europe');
  });

  test('simplifies TGT names and preserves supported countries', () {
    final catalog = PackageCatalog.fromProviderResponse(
      {
        'data': [
          {
            'productCode': 'E-185-ES-AU-EO1-T-30D-10GB',
            'planName': 'E-185-ES-AU-EO1-T-30D-10GB',
            'dataAmount': 10,
            'validityDays': 30,
            'supportedCountries': [
              {'name': 'Germany', 'code': 'DE'},
              {'name': 'France', 'code': 'FR'},
            ],
            'price': '9.00',
          },
        ],
      },
      provider: 'tgt',
      displayProvider: 'Orange Balkans',
    );

    final package = catalog.packages.single;
    expect(package.name, 'Orange Balkans 10GB 30 Days');
    expect(package.supportedCountries, hasLength(2));
    expect(package.supportedCountries.first.code, 'DE');
  });

  test('keeps destination label consistent with Europe coverage', () {
    final package = MobilePackage.fromJson({
      'id': 'orange-balkans-1gb',
      'name': 'Orange Balkans 1GB 3 Days',
      'provider': 'tgt',
      'destination_label': 'Global',
      'destination_key': 'europe',
      'data_quantity': 1,
      'package_validity': 3,
      'countries': [
        {'name': 'Europe', 'code': 'EU'},
      ],
    });

    expect(package.destinationKey, 'europe');
    expect(package.destination, 'Europe');
    expect(package.countryCode, 'EU');
  });
}
