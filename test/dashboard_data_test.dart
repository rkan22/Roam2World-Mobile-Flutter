import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/dashboard/dashboard_data.dart';

void main() {
  test('parses reseller dashboard response', () {
    final data = DashboardData.fromResponse({
      'success': true,
      'data': {
        'role': 'reseller',
        'current_credit': '125.50',
        'currency': 'USD',
        'today_sales': '20.00',
        'monthly_sales': '740.25',
        'total_esim_count': 15,
        'active_esim_count': 12,
        'expired_esim_count': 3,
        'recent_orders': [
          {
            'id': 9,
            'order_number': 'R2W-009',
            'product_name': 'Turkey 5GB',
            'status': 'completed',
            'total_amount': '15.00',
            'created_at': '2026-08-06T00:00:00Z',
          },
        ],
      },
    });

    expect(data.role, 'reseller');
    expect(data.balance, 125.5);
    expect(data.monthlySales, 740.25);
    expect(data.totalEsimCount, 15);
    expect(data.activeEsimCount, 12);
    expect(data.recentOrders.single.orderNumber, 'R2W-009');
    expect(data.recentOrders.single.productName, 'Turkey · 5GB');
  });

  test('accepts web dashboard KPI aliases and nested statistics', () {
    final data = DashboardData.fromResponse({
      'data': {
        'role': 'reseller',
        'totalSales': '1820.75',
        'statistics': {
          'total_esims': 28,
          'active_esims': 21,
          'expired_esims': 7,
        },
      },
    });

    expect(data.monthlySales, 1820.75);
    expect(data.totalEsimCount, 28);
    expect(data.activeEsimCount, 21);
    expect(data.expiredEsimCount, 7);
  });

  test('uses dealer current balance field', () {
    final data = DashboardData.fromResponse({
      'data': {
        'role': 'dealer',
        'current_balance': '44.10',
        'recent_orders': const [],
      },
    });

    expect(data.role, 'dealer');
    expect(data.balance, 44.1);
    expect(data.currency, 'USD');
  });

  test('simplifies provider package names in recent orders like web', () {
    final data = DashboardData.fromResponse({
      'data': {
        'recent_orders': [
          {
            'product_name': 'E-185-SC-AU-eO1-T-60D-20GB',
            'total_amount': '15.00',
          },
          {
            'product_name': '[eSIM] Europe (41 countries) / 10 GB / 30 Days',
          },
        ],
      },
    });

    expect(data.recentOrders.map((order) => order.productName), [
      '20GB · 60 Days',
      'Europe · 10GB · 30 Days',
    ]);
  });

  test('simplifies Worldmove package codes in recent orders', () {
    final data = DashboardData.fromResponse({
      'data': {
        'recent_orders': [
          {'product_name': 'WM-TR-10GB-30D'},
          {'product_name': 'WM-E-J1-WLD-O-MINI-30D'},
          {'product_name': 'WM-E-J1-VDFES-XL'},
        ],
      },
    });

    expect(data.recentOrders.map((order) => order.productName), [
      '10GB · 30 Days',
      '30 Days',
      'WM E J1 VDFES XL',
    ]);
  });
}
