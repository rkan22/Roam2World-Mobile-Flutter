import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/cache/timed_cache.dart';
import 'package_catalog.dart';

class PackagesRepository {
  PackagesRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static final Map<String, TimedCache<PackageCatalog>> _caches = {};
  final ApiClient _apiClient;
  bool lastFetchUsedStale = false;

  Future<PackageCatalog> fetchPackages({
    String? search,
    String? destination,
    String? packageType,
    String? provider,
    String? productKind,
    int? validityDays,
    double? dataGb,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    lastFetchUsedStale = false;
    final normalizedSearch = search?.trim() ?? '';
    final normalizedDestination = destination?.trim() ?? '';
    final normalizedType = packageType?.trim() ?? '';
    final normalizedProvider = provider?.trim() ?? '';
    final normalizedProductKind = productKind?.trim() ?? '';
    final cacheKey = [
      normalizedSearch.toLowerCase(),
      normalizedDestination.toLowerCase(),
      normalizedType.toLowerCase(),
      normalizedProvider.toLowerCase(),
      normalizedProductKind.toLowerCase(),
      validityDays?.toString() ?? '',
      dataGb?.toString() ?? '',
      limit.toString(),
    ].join('|');

    final cache = _caches.putIfAbsent(
      cacheKey,
      () => TimedCache<PackageCatalog>(ttl: const Duration(minutes: 3)),
    );
    if (!forceRefresh) {
      final cached = cache.value;
      if (cached != null) return cached;
    }

    try {
      final catalog = await _apiClient.get<PackageCatalog>(
        ApiEndpoints.mobilePackages,
        queryParameters: {
          'limit': limit,
          if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
          if (normalizedDestination.isNotEmpty) 'destination': normalizedDestination,
          if (normalizedType.isNotEmpty) 'package_type': normalizedType,
          if (normalizedProvider.isNotEmpty) 'provider': normalizedProvider,
          if (normalizedProductKind.isNotEmpty)
            'product_type': normalizedProductKind.toLowerCase() == 'sim card'
                ? 'simcard'
                : 'esim',
          if (validityDays != null) 'validity': validityDays,
          if (dataGb != null) 'data_gb': dataGb,
        },
        parser: PackageCatalog.fromResponse,
      );
      cache.set(catalog);
      return catalog;
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
    for (final cache in _caches.values) {
      cache.clear();
    }
    _caches.clear();
  }
}
