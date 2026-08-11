import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/customers/customers_repository.dart';

void main() {
  test('parses customer directory names and count', () {
    final directory = CustomerDirectory.fromResponse({
      'count': 3,
      'results': [
        {'first_name': 'Ada', 'last_name': 'Lovelace'},
        {'company_name': 'Roam Partner'},
      ],
    });

    expect(directory.count, 3);
    expect(directory.names, ['Ada Lovelace', 'Roam Partner']);
  });
}
