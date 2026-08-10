import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/cache/timed_cache.dart';
import '../../core/routing/app_role.dart';
import 'dashboard_data.dart';

class DashboardRepository {
  DashboardRepository({
    ApiClient? apiClient,
    this.role = AppRole.unknown,
  }) : _apiClient = apiClient ?? ApiClient();

  static final TimedCache<DashboardData> _tenantCache = TimedCache<DashboardData>(
    ttl: const Duration(seconds: 60),
  );
  static final TimedCache<DashboardData> _adminCache = TimedCache<DashboardData>(
    ttl: const Duration(seconds: 60),
  );

  final ApiClient _apiClient;
  final AppRole role;
  bool lastFetchUsedStale = false;

  TimedCache<DashboardData> get _cache =>
      role == AppRole.admin ? _adminCache : _tenantCache;

  Future<DashboardData> fetchDashboard({bool forceRefresh = false}) async {
    lastFetchUsedStale = false;
    if (!forceRefresh) {
      final cached = _cache.value;
      if (cached != null) return cached;
    }

    try {
      final isAdmin = role == AppRole.admin;
      final data = await _apiClient.get<DashboardData>(
        isAdmin ? ApiEndpoints.mobileAdminDashboard : ApiEndpoints.mobileDashboard,
        parser: isAdmin
            ? DashboardData.fromAdminResponse
            : DashboardData.fromResponse,
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
