import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
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
    } catch (_) {
      final stale = _cache.staleValue;
      if (stale != null) {
        lastFetchUsedStale = true;
        return stale;
      }

      rethrow;
    }
  }

  void invalidateCache() => _cache.clear();
}
