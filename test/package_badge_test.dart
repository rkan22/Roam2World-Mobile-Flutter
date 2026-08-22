import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/packages/package_catalog.dart';

Map<String, dynamic> packageJson(Map<String, dynamic> extra) => {
  'id': 'plan-1',
  'name': 'Europe 10GB',
  'provider': 'airhub',
  'price': '15.00',
  'is_price_visible': true,
  ...extra,
};

void main() {
  test('uses only explicit backend promotional badge signals', () {
    expect(
      MobilePackage.fromJson(packageJson({'is_best_seller': true})).badgeLabel,
      'Best Seller',
    );
    expect(
      MobilePackage.fromJson(packageJson({'is_best_value': true})).badgeLabel,
      'Best Value',
    );
    expect(
      MobilePackage.fromJson(packageJson({'is_new': true})).badgeLabel,
      'New',
    );
    expect(
      MobilePackage.fromJson(packageJson({'is_featured': true})).badgeLabel,
      'Featured',
    );
    expect(MobilePackage.fromJson(packageJson({})).badgeLabel, isNull);
  });

  test('preserves badge when central pricing updates the price', () {
    final package = MobilePackage.fromJson(packageJson({'is_featured': true}));

    expect(package.withPrice(19).badgeLabel, 'Featured');
  });
}
