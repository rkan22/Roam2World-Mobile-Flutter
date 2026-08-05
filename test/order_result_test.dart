import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/orders/order_result.dart';

void main() {
  test('parses mobile order creation response', () {
    final result = MobileOrderResult.fromResponse({
      'success': true,
      'data': {
        'order_id': 42,
        'order_number': 'MOB-42',
        'order_status': 'completed',
        'package_name': 'Turkey 10GB',
        'total_amount': '15.50',
        'currency': 'USD',
        'esim_id': 7,
        'qr_code': r'LPA:1$smdp.example$MATCH',
        'activation_code': 'MATCH',
        'install_available': true,
        'customer_first_name': 'Ada',
        'customer_last_name': 'Lovelace',
      },
    });

    expect(result.orderId, '42');
    expect(result.orderNumber, 'MOB-42');
    expect(result.customerName, 'Ada Lovelace');
    expect(result.esimId, '7');
    expect(result.installAvailable, isTrue);
    expect(result.formattedTotal, 'USD 15.50');
  });
}
