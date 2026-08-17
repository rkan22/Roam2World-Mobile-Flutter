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
          {'product_name': '[eSIM] Europe (41 countries) / 10 GB / 30 Days'},
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

  test('parses the current admin dashboard API contract', () {
    final data = DashboardData.fromAdminResponse({
      'success': true,
      'data': {
        'period': '30d',
        'currency': 'USD',
        'kpis': {
          'revenue': '432.67',
          'gross_profit': '94.29',
          'gross_margin_percent': '21.79',
          'completed_orders': 21,
          'total_orders': 40,
          'active_esims': 4,
          'active_resellers': 1,
          'active_dealers': 1,
        },
        'orders_by_status': {
          'cancelled': 14,
          'completed': 21,
          'confirmed': 1,
          'failed': 3,
          'processing': 1,
        },
        'daily_operations': {
          'wallet_requests_pending': 1,
          'manual_fulfillment_pending': 1,
          'provider_retries_requiring_review': 0,
          'support_tickets_open': 0,
          'available_blank_sims': 147,
        },
        'partner_performance': {
          'resellers': [
            {'id': 43},
          ],
          'dealers': [
            {'id': 20},
          ],
        },
        'latest_orders': [
          {
            'id': 917,
            'order_number': 'ORD-917',
            'status': 'processing',
            'product_name': 'Movistar eSIM 300GB 28 Days',
            'total_amount': '25.90',
          },
        ],
      },
    });

    expect(data.currency, 'USD');
    expect(data.monthlySales, 432.67);
    expect(data.grossProfit, 94.29);
    expect(data.totalOrders, 40);
    expect(data.pendingOrders, 2);
    expect(data.completedOrders, 21);
    expect(data.failedOrders, 3);
    expect(data.resellerCount, 1);
    expect(data.dealerCount, 1);
    expect(data.activeEsimCount, 4);
    expect(data.pendingWalletRequests, 1);
    expect(data.manualFulfillmentPending, 1);
    expect(data.providerRetriesRequiringReview, 0);
    expect(data.supportTicketsOpen, 0);
    expect(data.availableBlankSims, 147);
    expect(data.recentOrders.single.id, 917);
  });
}
