import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/wallet/wallet_request.dart';

void main() {
  test('parses pending wallet top-up request', () {
    final request = WalletRequest.fromResponse({
      'id': 17,
      'requested_amount': '125.50',
      'currency': 'USD',
      'status': 'pending',
      'note': 'Need balance for sales',
      'created_at': '2026-08-06T00:00:00Z',
    });

    expect(request.id, 17);
    expect(request.amount, 125.50);
    expect(request.currency, 'USD');
    expect(request.status, 'pending');
    expect(request.note, 'Need balance for sales');
  });
}
