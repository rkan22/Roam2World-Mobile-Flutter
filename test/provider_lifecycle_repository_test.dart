import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/esims/provider_lifecycle_repository.dart';

void main() {
  test('provider operation response keeps normalized provider data', () {
    final result = ProviderOperationResult.fromResponse({
      'success': true,
      'provider': 'worldmove',
      'message': 'Top-up completed.',
      'data': {'provider_order_id': 'WM-1'},
    });

    expect(result.success, isTrue);
    expect(result.provider, 'worldmove');
    expect(result.message, 'Top-up completed.');
    expect(result.data['provider_order_id'], 'WM-1');
  });

  test('TGT bulk item omits empty optional customer fields', () {
    const item = TgtBulkItem(
      packageId: 'TGT-10GB',
      iccid: '8944000000000000000',
      customerEmail: '',
    );

    expect(item.toJson(), {
      'package_id': 'TGT-10GB',
      'iccid': '8944000000000000000',
    });
  });
}
