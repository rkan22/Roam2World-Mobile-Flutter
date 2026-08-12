import 'package:flutter_test/flutter_test.dart';

String buildCheckoutKey({
  required String packageId,
  required String packageType,
  required String firstName,
  required String lastName,
  required String phone,
  String? email,
  String? imei,
  String? simNumber,
}) {
  return [
    packageId,
    packageType,
    firstName.trim().toLowerCase(),
    lastName.trim().toLowerCase(),
    phone.trim(),
    email?.trim().toLowerCase() ?? '',
    imei?.trim() ?? '',
    simNumber?.replaceAll(RegExp(r'\D'), '') ?? '',
  ].join('|');
}

void main() {
  test('checkout key is stable across whitespace/case normalization', () {
    final first = buildCheckoutKey(
      packageId: 'pkg-1',
      packageType: 'esim',
      firstName: ' John ',
      lastName: ' DOE',
      phone: ' +90 555 ',
      email: ' USER@EXAMPLE.COM ',
      imei: ' 123 ',
      simNumber: '89-123',
    );
    final retry = buildCheckoutKey(
      packageId: 'pkg-1',
      packageType: 'esim',
      firstName: 'john',
      lastName: 'doe',
      phone: '+90 555',
      email: 'user@example.com',
      imei: '123',
      simNumber: '89123',
    );

    expect(retry, first);
  });

  test('different checkout payloads get different keys', () {
    final first = buildCheckoutKey(
      packageId: 'pkg-1',
      packageType: 'esim',
      firstName: 'John',
      lastName: 'Doe',
      phone: '555',
    );
    final second = buildCheckoutKey(
      packageId: 'pkg-2',
      packageType: 'esim',
      firstName: 'John',
      lastName: 'Doe',
      phone: '555',
    );

    expect(second, isNot(first));
  });
}
