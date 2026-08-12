import 'package:flutter_test/flutter_test.dart';

class _SimCardPackage {
  const _SimCardPackage({required this.id, required this.name, required this.price, required this.currency});
  final String id;
  final String name;
  final double price;
  final String currency;

  factory _SimCardPackage.fromJson(Map<String, dynamic> json) => _SimCardPackage(
        id: json['productId']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? json['packageName']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        currency: json['currency']?.toString() ?? 'USD',
      );
}

void main() {
  test('parses physical SIM catalog payload', () {
    final package = _SimCardPackage.fromJson({
      'productId': 'SIM-100',
      'name': 'Global Physical SIM',
      'price': 12.5,
      'currency': 'USD',
    });

    expect(package.id, 'SIM-100');
    expect(package.name, 'Global Physical SIM');
    expect(package.price, 12.5);
    expect(package.currency, 'USD');
  });

  test('falls back to generic id/packageName fields', () {
    final package = _SimCardPackage.fromJson({
      'id': 42,
      'packageName': 'Regional SIM',
      'price': 8,
    });

    expect(package.id, '42');
    expect(package.name, 'Regional SIM');
    expect(package.currency, 'USD');
  });
}
