import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/admin/admin_commercial_repository.dart';
import 'package:roam2world_mobile_flutter/features/operations/operations_data.dart';

void main() {
  test('parses dedicated admin reports response', () {
    final report = AdminReportsSnapshot.fromResponse({
      'data': {
        'orders': {'total': 120, 'completed': 100, 'failed': 4},
        'revenue': {'total_sales': '9876.54', 'currency': 'USD'},
        'resellers': {'total': 8, 'active': 7},
        'dealers': {'total': 24, 'active': 20},
      },
    });

    expect(report.totalOrders, 120);
    expect(report.completedOrders, 100);
    expect(report.failedOrders, 4);
    expect(report.totalSales, 9876.54);
    expect(report.activeDealers, 20);
  });

  test('parses complete admin system health response', () {
    final health = SystemHealthData.fromResponse({
      'data': {
        'api': 'operational',
        'database': 'available',
        'orders': 'operational',
        'wallet': 'operational',
        'provider_health': {
          'status': 'available',
          'endpoint': '/api/v1/providers/balances/',
          'refresh_seconds': 60,
        },
      },
    });

    expect(health.isOperational, isTrue);
    expect(health.providerEndpoint, '/api/v1/providers/balances/');
    expect(health.providerRefreshSeconds, 60);
  });

  test('preserves admin activity actor, target and summary', () {
    final activity = AdminActivityData.fromResponse({
      'data': {
        'logs': [
          {
            'type': 'order',
            'title': 'Order activity',
            'message': 'R2W-42 - completed',
            'actor': 'order-system',
            'status': 'completed',
            'created_at': '2026-08-11T10:00:00Z',
          },
        ],
        'summary': {
          'users': 30,
          'orders': 120,
          'resellers': 8,
          'dealers': 24,
          'esims': 110,
          'plans': 45,
        },
      },
    });

    expect(activity.events.single.actor, 'order-system');
    expect(activity.events.single.action, 'order');
    expect(activity.events.single.target, 'Order activity');
    expect(activity.summary.orders, 120);
    expect(activity.summary.esims, 110);
  });
}
