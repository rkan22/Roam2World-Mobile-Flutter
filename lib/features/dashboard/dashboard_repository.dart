import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/cache/timed_cache.dart';
import '../../core/routing/app_role.dart';
import '../../core/storage/token_storage.dart';
import 'dashboard_data.dart';

class DashboardRepository {
  DashboardRepository({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    this.role = AppRole.unknown,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  static final TimedCache<DashboardData> _tenantCache = TimedCache<DashboardData>(
    ttl: const Duration(seconds: 60),
  );
  static final TimedCache<DashboardData> _adminCache = TimedCache<DashboardData>(
    ttl: const Duration(seconds: 60),
  );

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final AppRole role;
  bool lastFetchUsedStale = false;

  Future<AppRole> _effectiveRole() async {
    if (role != AppRole.unknown) return role;
    final profile = await _tokenStorage.readProfile();
    return parseAppRole(profile?['role']?.toString());
  }

  Future<DashboardData> fetchDashboard({bool forceRefresh = false}) async {
    lastFetchUsedStale = false;
    final effectiveRole = await _effectiveRole();
    final cache = effectiveRole == AppRole.admin ? _adminCache : _tenantCache;

    if (!forceRefresh) {
      final cached = cache.value;
      if (cached != null) return cached;
    }

    try {
      final isAdmin = effectiveRole == AppRole.admin;
      final data = await _apiClient.get<DashboardData>(
        isAdmin ? ApiEndpoints.mobileAdminDashboard : ApiEndpoints.mobileDashboard,
        parser: isAdmin
            ? DashboardData.fromAdminResponse
            : DashboardData.fromResponse,
      );
      cache.set(data);
      return data;
    } catch (_) {
      final stale = cache.staleValue;
      if (stale != null) {
        lastFetchUsedStale = true;
        return stale;
      }

      rethrow;
    }
  }

  void invalidateCache() {
    if (role == AppRole.admin) {
      _adminCache.clear();
      return;
    }
    if (role == AppRole.unknown) {
      _adminCache.clear();
      _tenantCache.clear();
      return;
    }
    _tenantCache.clear();
  }
}
