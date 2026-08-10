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

  test('parses wallet request history response', () {
    final requests = WalletRequest.listFromResponse([
      {
        'id': 18,
        'amount': '75.00',
        'currency': 'USD',
        'status': 'approved',
        'note': 'Approved funding',
      },
    ]);

    expect(requests, hasLength(1));
    expect(requests.single.status, 'approved');
    expect(requests.single.amount, 75);
  });

  test('parses admin review request and nested requester', () {
    final request = WalletRequest.fromResponse({
      'success': true,
      'data': {
        'id': 21,
        'request_type': 'reseller_topup_request',
        'amount': '500.00',
        'currency': 'USD',
        'status': 'pending',
        'reseller': {'name': 'Demo Reseller', 'email': 'reseller@example.com'},
      },
    });

    expect(request.requestType, 'reseller_topup_request');
    expect(request.requesterName, 'Demo Reseller');
    expect(request.requesterEmail, 'reseller@example.com');
    expect(request.isPending, isTrue);
  });
}
