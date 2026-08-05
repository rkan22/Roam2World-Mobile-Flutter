import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/notifications/notification_data.dart';

void main() {
  test('parses mobile notification response', () {
    final items = parseMobileNotifications({
      'success': true,
      'data': {
        'notifications': [
          {
            'id': 7,
            'title': 'Order completed',
            'message': 'Your eSIM is ready.',
            'type': 'order',
            'is_read': false,
            'created_at': '2026-08-06T00:30:00Z',
            'related_order_id': 44,
            'metadata': {'action_label': 'Open order'},
          },
        ],
      },
    });

    expect(items, hasLength(1));
    expect(items.first.id, 7);
    expect(items.first.isRead, isFalse);
    expect(items.first.type, 'order');
    expect(items.first.relatedOrderId, 44);
    expect(items.first.metadata['action_label'], 'Open order');
  });

  test('also accepts a direct notification list', () {
    final items = parseMobileNotifications({
      'data': [
        {
          'id': 8,
          'title': 'Wallet updated',
          'message': 'Approved',
          'type': 'wallet',
          'is_read': true,
        },
      ],
    });

    expect(items.single.isRead, isTrue);
  });
}
