import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../core/cache/timed_cache.dart';
import 'dashboard_data.dart';

class DashboardRepository {
  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static final TimedCache<DashboardData> _cache = TimedCache<DashboardData>(
    ttl: const Duration(seconds: 60),
  );

  final ApiClient _apiClient;
  bool lastFetchUsedStale = false;

  Future<DashboardData> fetchDashboard({bool forceRefresh = false}) async {
    lastFetchUsedStale = false;
    if (!forceRefresh) {
      final cached = _cache.value;
      if (cached != null) return cached;
    }

    try {
      final data = await _apiClient.get<DashboardData>(
        ApiEndpoints.mobileDashboard,
        parser: DashboardData.fromResponse,
      );
      _cache.set(data);
      return data;
    } catch (error) {
      final stale = _cache.staleValue;
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

  void invalidateCache() => _cache.clear();
}

final DashboardData _debugDemoData = DashboardData(
  role: 'Super Administrator',
  balance: 2450.50,
  currency: r'$' ,
  todaySales: 1234,
  monthlySales: 15678,
  activeEsimCount: 245,
  expiredEsimCount: 12,
  recentOrders: [
    DashboardOrderSummary(
      id: 1,
      orderNumber: 'DEMO-001',
      productName: '10 x Europe eSIM',
      status: 'completed',
      totalAmount: 200,
      createdAt: null,
    ),
  ],
);
