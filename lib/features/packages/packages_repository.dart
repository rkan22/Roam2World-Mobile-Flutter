import '../../core/api/api_client.dart';
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
    if (!forceRefresh && cache.value != null) return cache.value!;

    try {
      final catalog = await _apiClient.get<PackageCatalog>(
        '/api/v1/mobile/b2b/packages/',
        queryParameters: {
          'limit': limit,
          if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
          if (normalizedDestination.isNotEmpty) 'category': normalizedDestination,
          if (normalizedType.isNotEmpty) 'type': normalizedType,
        },
        parser: PackageCatalog.fromResponse,
      );

      final filtered = catalog.packages.where((package) {
        if (normalizedDestination.isNotEmpty &&
            package.destinationKey.toLowerCase() != normalizedDestination.toLowerCase()) {
          return false;
        }
        if (normalizedType.isNotEmpty &&
            package.packageType.toLowerCase() != normalizedType.toLowerCase()) {
          return false;
        }
        if (normalizedSearch.isEmpty) return true;
        final term = normalizedSearch.toLowerCase();
        return [
          package.name,
          package.destination,
          package.displayProvider,
          package.provider,
          package.id,
          package.dataLabel,
          package.validityLabel,
        ].any((value) => value.toLowerCase().contains(term));
      }).toList(growable: false);

      final result = PackageCatalog(
        packages: filtered,
        hasMore: catalog.hasMore,
      );
      cache.set(result);
      return result;
    } catch (_) {
      final stale = cache.staleValue;
      if (stale != null) {
        lastFetchUsedStale = true;
        return stale;
      }
      rethrow;
    }
  }

  Future<List<String>> fetchCategories() async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/mobile/b2b/categories/',
      parser: (raw) => raw,
    );
    return _extractCategories(response);
  }

  List<String> _extractCategories(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => '${item['slug'] ?? item['id'] ?? item['name'] ?? ''}'.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    if (response is Map) {
      final data = response['data'] ?? response['categories'] ?? response['results'];
      if (data is List) return _extractCategories(data);
    }
    return const [];
  }

  void invalidateCache() {
    for (final cache in _caches.values) {
      cache.clear();
    }
    _caches.clear();
  }
}
