import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/orders/order_history.dart';

void main() {
  test('parses mobile order history response', () {
    final history = OrderHistory.fromResponse({
      'success': true,
      'data': {
        'count': 1,
        'orders': [
          {
            'id': 42,
            'order_number': 'ORD-42',
            'package_name': 'Europe 20GB',
            'customer_name': 'Ada Lovelace',
            'status': 'completed',
            'price': '24.50',
            'currency': 'USD',
            'created_at': '2026-08-05T20:00:00Z',
            'esim_id': 8,
          }
        ],
      },
    });

    expect(history.count, 1);
    expect(history.orders.single.orderNumber, 'ORD-42');
    expect(history.orders.single.packageName, 'Europe · 20GB');
    expect(history.orders.single.amount, 24.5);
    expect(history.orders.single.esimId, 8);
  });
}
