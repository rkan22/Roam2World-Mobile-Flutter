import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/wallet/wallet_data.dart';

void main() {
  test('parses reseller wallet response', () {
    final wallet = WalletData.fromResponse({
      'success': true,
      'data': {
        'role': 'reseller',
        'current_credit': '1234.56',
        'available_credit': '1200.00',
        'credit_limit': '2500.00',
        'currency': 'USD',
        'recent_transactions': [
          {
            'id': 1,
            'transaction_type': 'topup',
            'status': 'completed',
            'amount': '100.00',
            'currency': 'USD',
            'description': 'Wallet top-up',
            'created_at': '2026-08-05T20:00:00Z',
          }
        ],
      },
    });

    expect(wallet.isDealer, isFalse);
    expect(wallet.availableAmount, 1200);
    expect(wallet.secondaryLabel, 'Credit limit');
    expect(wallet.transactions.single.isCredit, isTrue);
  });

  test('parses dealer wallet response', () {
    final wallet = WalletData.fromResponse({
      'data': {
        'role': 'dealer',
        'current_balance': '321.09',
        'available_balance': '300.00',
        'total_spent': '178.91',
        'currency': 'USD',
        'recent_transactions': [],
      },
    });

    expect(wallet.isDealer, isTrue);
    expect(wallet.currentAmount, 321.09);
    expect(wallet.secondaryLabel, 'Total spent');
  });
}
