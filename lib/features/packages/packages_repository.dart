import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/cache/timed_cache.dart';
import 'package_catalog.dart';

class PackagesRepository {
  PackagesRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static final Map<String, TimedCache<PackageCatalog>> _caches = {};
  final ApiClient _apiClient;

  Future<PackageCatalog> fetchPackages({
    String? search,
    String? destination,
    String? packageType,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    final normalizedSearch = search?.trim() ?? '';
    final normalizedDestination = destination?.trim() ?? '';
    final normalizedType = packageType?.trim() ?? '';
    final cacheKey = [
      normalizedSearch.toLowerCase(),
      normalizedDestination.toLowerCase(),
      normalizedType.toLowerCase(),
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

    final catalog = await _apiClient.get<PackageCatalog>(
      ApiEndpoints.mobilePackages,
      queryParameters: {
        'limit': limit,
        if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
        if (normalizedDestination.isNotEmpty) 'destination': normalizedDestination,
        if (normalizedType.isNotEmpty) 'package_type': normalizedType,
      },
      parser: PackageCatalog.fromResponse,
    );
    cache.set(catalog);
    return catalog;
  }

  void invalidateCache() {
    for (final cache in _caches.values) {
      cache.clear();
    }
    _caches.clear();
  }
}
