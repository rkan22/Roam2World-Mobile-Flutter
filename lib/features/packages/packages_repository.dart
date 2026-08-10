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
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    lastFetchUsedStale = false;
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

    try {
      final packages = <MobilePackage>[];
      final seenIds = <String>{};
      var offset = 0;
      var hasMore = true;
      var pageCount = 0;

      while (hasMore && pageCount < 20) {
        final page = await _apiClient.get<PackageCatalog>(
          ApiEndpoints.mobilePackages,
          queryParameters: {
            'limit': limit,
            'offset': offset,
            if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
            if (normalizedDestination.isNotEmpty) 'destination': normalizedDestination,
            if (normalizedType.isNotEmpty) 'package_type': normalizedType,
          },
          parser: PackageCatalog.fromResponse,
        );

        var added = 0;
        for (final package in page.packages) {
          final dedupeKey = package.id.isEmpty
              ? '${package.provider}|${package.name}|${package.destination}|${package.price}'
              : package.id;
          if (seenIds.add(dedupeKey)) {
            packages.add(package);
            added++;
          }
        }

        hasMore = page.hasMore;
        if (!hasMore || page.packages.isEmpty || added == 0) break;

        offset += page.packages.length;
        pageCount++;
      }

      final catalog = PackageCatalog(packages: packages, hasMore: hasMore);
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
