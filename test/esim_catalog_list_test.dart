import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/esims/esim_catalog.dart';

void main() {
  test('accepts mobile eSIM data as a direct list', () {
    final catalog = EsimCatalog.fromResponse({
      'count': 1,
      'data': [
        {'id': 7, 'provider': 'tgt', 'status': 'active'},
      ],
    });

    expect(catalog.count, 1);
    expect(catalog.esims.single.id, 7);
  });
}
