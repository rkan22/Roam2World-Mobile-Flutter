import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/cache/timed_cache.dart';
import '../../core/routing/app_role.dart';
import '../../core/storage/token_storage.dart';
import '../esims/esim_catalog.dart';
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

  Future<DashboardData> fetchDashboard({
    bool forceRefresh = false,
    String? period,
  }) async {
    lastFetchUsedStale = false;
    final effectiveRole = await _effectiveRole();
    final cache = effectiveRole == AppRole.admin ? _adminCache : _tenantCache;
    final explicitPeriod = period != null && period.trim().isNotEmpty;
    final useCache = !explicitPeriod;

    if (!forceRefresh && useCache) {
      final cached = cache.value;
      if (cached != null) return cached;
    }

    try {
      final isAdmin = effectiveRole == AppRole.admin;
      var data = await _apiClient.get<DashboardData>(
        isAdmin
            ? ApiEndpoints.mobileAdminDashboard
            : ApiEndpoints.mobileDashboard,
        queryParameters: !isAdmin && explicitPeriod
            ? {'period': period.trim()}
            : null,
        parser: isAdmin
            ? DashboardData.fromAdminResponse
            : DashboardData.fromResponse,
      );
      if (!isAdmin) data = await _enrichPartnerDashboard(data);
      if (useCache) cache.set(data);
      return data;
    } catch (_) {
      if (useCache) {
        final stale = cache.staleValue;
        if (stale != null) {
          lastFetchUsedStale = true;
          return stale;
        }
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
    } catch (_) {}

    try {
      final history = await _apiClient.get<OrderHistory>(
        ApiEndpoints.mobileOrders,
        parser: OrderHistory.fromResponse,
      );
      final successfulOrders = history.orders
          .where((order) {
            final status = order.status.toLowerCase();
            return status != 'failed' &&
                status != 'cancelled' &&
                status != 'canceled' &&
                status != 'refunded';
          })
          .toList(growable: false);
      final now = DateTime.now();
      final todaySales = successfulOrders
          .where((order) {
            final createdAt = order.createdAt?.toLocal();
            return createdAt != null &&
                createdAt.year == now.year &&
                createdAt.month == now.month &&
                createdAt.day == now.day;
          })
          .fold<double>(0, (sum, order) => sum + order.amount);
      final totalSales = successfulOrders.fold<double>(
        0,
        (sum, order) => sum + order.amount,
      );
      result = result.copyWith(
        todaySales: result.todaySales == 0 ? todaySales : null,
        monthlySales: result.monthlySales == 0 ? totalSales : null,
        recentOrders: history.orders
            .take(5)
            .map(
              (order) => DashboardOrderSummary(
                id: order.id,
                orderNumber: order.orderNumber,
                productName: order.packageName,
                status: order.status,
                totalAmount: order.amount,
                createdAt: order.createdAt,
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {}

    try {
      final catalog = await _apiClient.get<EsimCatalog>(
        ApiEndpoints.mobileEsims,
        queryParameters: const {'limit': 200},
        parser: EsimCatalog.fromResponse,
      );
      final now = DateTime.now();
      final expired = catalog.esims.where((esim) {
        final status = esim.status.toLowerCase();
        return status == 'expired' ||
            (esim.expiresAt != null && esim.expiresAt!.isBefore(now));
      }).length;
      const activeStatuses = {
        'active',
        'activated',
        'assigned',
        'provisioned',
        'ready',
      };
      final active = catalog.esims.where((esim) {
        return activeStatuses.contains(esim.status.toLowerCase()) &&
            (esim.expiresAt == null || esim.expiresAt!.isAfter(now));
      }).length;
      result = result.copyWith(
        totalEsimCount: catalog.count,
        activeEsimCount: result.activeEsimCount == 0 ? active : null,
        expiredEsimCount: result.expiredEsimCount == 0 ? expired : null,
      );
    } catch (_) {}
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
