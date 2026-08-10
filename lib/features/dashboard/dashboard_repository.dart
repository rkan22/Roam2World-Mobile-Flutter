import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../core/cache/timed_cache.dart';
import 'dashboard_data.dart';

class DashboardRepository {
  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static final Map<String, TimedCache<DashboardData>> _caches = {};

  final ApiClient _apiClient;
  bool lastFetchUsedStale = false;

  TimedCache<DashboardData> _cacheFor(String period) =>
      _caches.putIfAbsent(
        period,
        () => TimedCache<DashboardData>(ttl: const Duration(seconds: 60)),
      );

  Future<DashboardData> fetchDashboard({
    bool forceRefresh = false,
    String period = '30d',
  }) async {
    lastFetchUsedStale = false;
    final cache = _cacheFor(period);

    if (!forceRefresh) {
      final cached = cache.value;
      if (cached != null) return cached;
    }

    try {
      final data = await _apiClient.get<DashboardData>(
        ApiEndpoints.mobileDashboard,
        queryParameters: {'period': period},
        parser: DashboardData.fromResponse,
      );
      cache.set(data);
      return data;
    } catch (error) {
      final stale = cache.staleValue;
      if (stale != null) {
        lastFetchUsedStale = true;
        return stale;
      }

      if (kDebugMode &&
          error is ApiException &&
          error.message.toLowerCase().contains('role is required')) {
        return _debugDemoData;
      }

      rethrow;
    }
  }

  void invalidateCache() {
    for (final cache in _caches.values) {
      cache.clear();
    }
  }
}

final DashboardData _debugDemoData = DashboardData(
  role: 'Reseller',
  balance: 2450.50,
  currency: r'$',
  todaySales: 1234,
  monthlySales: 15678,
  activeEsimCount: 245,
  expiredEsimCount: 12,
  revenue: 15678,
  grossProfit: 4230,
  grossMarginPercent: 26.98,
  successfulOrders: 184,
  totalCustomers: 93,
  recentOrders: [
    DashboardOrderSummary(
      id: 1,
      orderNumber: 'DEMO-001',
      productName: 'Europe · 10GB · 30 Days',
      status: 'completed',
      totalAmount: 200,
      createdAt: null,
    ),
  ],
);
