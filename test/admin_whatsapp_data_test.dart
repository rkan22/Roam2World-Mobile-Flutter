import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/admin/admin_whatsapp_data.dart';

void main() {
  test('parses admin WhatsApp workspace response', () {
    final data = AdminWhatsAppData.fromResponse({
      'success': true,
      'connection': {
        'enabled': true,
        'phone_number_configured': true,
        'access_token_configured': true,
        'webhook_secret_configured': true,
      },
      'delivery': {'sent': 10, 'failed': 2},
      'templates': [
        {
          'event': 'order_ready',
          'template_name': 'order_ready_v1',
          'language': 'en',
          'status': 'sent',
          'total': 8,
        },
      ],
      'catalog': [
        {
          'id': 4,
          'provider': 'worldmove',
          'package_id': 'WM-TR-10',
          'package_name': 'Turkey 10GB',
          'customer_price': '24.50',
          'supplier_price': '18.00',
          'pricing_status': 'priced',
          'featured': true,
        },
      ],
      'manual_approvals': [
        {
          'id': 7,
          'operation': 'purchase',
          'package_name': 'Turkey 10GB',
          'provider': 'worldmove',
          'customer_phone': '+905551112233',
          'amount': '24.50',
          'currency': 'USD',
          'created_at': '2026-08-11T12:00:00Z',
        },
      ],
    });

    expect(data.connection.isReady, isTrue);
    expect(data.delivery['sent'], 10);
    expect(data.templates.single.total, 8);
    expect(data.catalog.single.customerPrice, 24.50);
    expect(data.catalog.single.featured, isTrue);
    expect(data.manualApprovals.single.customerPhone, '+905551112233');
  });

  test('serializes only backend-supported catalog update fields', () {
    final item = WhatsAppCatalogItem.fromJson({
      'id': 4,
      'provider': 'worldmove',
      'package_id': 'WM-TR-10',
      'package_name': 'Turkey 10GB',
      'featured': false,
    });

    expect(item.toUpdateJson(featured: true), {
      'id': 4,
      'provider': 'worldmove',
      'package_id': 'WM-TR-10',
      'package_name': 'Turkey 10GB',
      'featured': true,
    });
  });
}
