import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/cache/timed_cache.dart';
import '../../core/routing/app_role.dart';
import '../../core/storage/token_storage.dart';
import '../orders/order_history.dart';
import '../wallet/wallet_data.dart';
import 'dashboard_data.dart';

class DashboardRepository {
  DashboardRepository({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    this.role = AppRole.unknown,
  }) : _apiClient = apiClient ?? ApiClient(),
       _tokenStorage = tokenStorage ?? TokenStorage();

  final TimedCache<DashboardData> _tenantCache = TimedCache<DashboardData>(
    ttl: const Duration(seconds: 60),
  );
  final TimedCache<DashboardData> _adminCache = TimedCache<DashboardData>(
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
      var data = await _apiClient.get<DashboardData>(
        isAdmin
            ? ApiEndpoints.mobileAdminDashboard
            : ApiEndpoints.mobileDashboard,
        parser: isAdmin
            ? DashboardData.fromAdminResponse
            : DashboardData.fromResponse,
      );
      if (!isAdmin) {
        data = await _enrichPartnerDashboard(data);
      }
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

  Future<DashboardData> _enrichPartnerDashboard(DashboardData dashboard) async {
    var result = dashboard;
    try {
      final wallet = await _apiClient.get<WalletData>(
        ApiEndpoints.mobileWallet,
        parser: WalletData.fromResponse,
      );
      result = result.copyWith(
        balance: wallet.currentAmount,
        currency: wallet.currency,
      );
    } catch (_) {
      // The dashboard payload remains usable if the wallet service is down.
    }

    try {
      final history = await _apiClient.get<OrderHistory>(
        ApiEndpoints.mobileOrders,
        parser: OrderHistory.fromResponse,
      );
      result = result.copyWith(
        recentOrders: history.orders
            .take(5)
            .map((order) {
              return DashboardOrderSummary(
                id: order.id,
                orderNumber: order.orderNumber,
                productName: order.packageName,
                status: order.status,
                totalAmount: order.amount,
                createdAt: order.createdAt,
              );
            })
            .toList(growable: false),
      );
    } catch (_) {
      // Preserve recent orders from the dashboard endpoint on partial failure.
    }
    return result;
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
