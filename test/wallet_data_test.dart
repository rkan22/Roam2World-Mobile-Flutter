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
          },
        ],
      },
    });

    expect(wallet.isDealer, isFalse);
    expect(wallet.availableAmount, 1200);
    expect(wallet.secondaryLabel, 'Credit limit');
    expect(wallet.transactions.single.isCredit, isTrue);
  });

  test('parses complete transaction history including payment ids', () {
    final page = WalletTransactionPage.fromResponse({
      'transactions': [
        {
          'id': 'payment-9',
          'transaction_type': 'payment',
          'status': 'completed',
          'amount': '42.25',
          'currency': 'USD',
          'description': 'Europe 10 GB',
          'created_at': '2026-08-06T12:00:00Z',
        },
      ],
      'balance': '100.00',
      'currency': 'USD',
    });

    expect(page.transactions.single.id, 'payment-9');
    expect(page.transactions.single.isCredit, isFalse);
    expect(page.balance, 100);
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

  test('parses admin wallet summary without enabling top-up', () {
    final wallet = WalletData.fromResponse({
      'data': {
        'role': 'admin',
        'currency': 'USD',
        'pending_wallet_requests': 7,
      },
    });

    expect(wallet.isAdmin, isTrue);
    expect(wallet.canRequestTopUp, isFalse);
    expect(wallet.secondaryAmount, 7);
    expect(wallet.secondaryLabel, 'Pending requests');
  });

  test('uses balance movement for adjustment direction', () {
    final credit = WalletTransaction.fromJson({
      'id': 30,
      'transaction_type': 'adjustment',
      'amount': '25.00',
      'balance_before': '100.00',
      'balance_after': '125.00',
    });
    final debit = WalletTransaction.fromJson({
      'id': 31,
      'transaction_type': 'adjustment',
      'amount': '-10.00',
      'balance_before': '125.00',
      'balance_after': '115.00',
    });

    expect(credit.isCredit, isTrue);
    expect(debit.isCredit, isFalse);
    expect(debit.displayAmount, 10);
  });

  test('recognizes bonus as credit and payment as debit', () {
    final bonus = WalletTransaction.fromJson({
      'transaction_type': 'bonus',
      'amount': '5.00',
    });
    final payment = WalletTransaction.fromJson({
      'id': 'payment-4',
      'transaction_type': 'payment',
      'amount': '20.00',
    });

    expect(bonus.isCredit, isTrue);
    expect(payment.isCredit, isFalse);
  });
}
