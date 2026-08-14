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
      final externalPackages = <MobilePackage>[];
      final seenIds = <String>{};
      var offset = 0;
      var hasMore = true;
      var pageCount = 0;

      while (hasMore && pageCount < 20) {
        final page = await _apiClient.get<PackageCatalog>(
          ApiEndpoints.mobilePackages,
          queryParameters: {'limit': limit, 'offset': offset},
          parser: PackageCatalog.fromResponse,
        );

        var added = 0;
        for (final package in page.packages) {
          if (_isHiddenProvider(package)) continue;
          final dedupeKey = package.id.isEmpty
              ? '${package.provider}|${package.name}|${package.destination}|${package.price}'
              : '${package.provider}|${package.id}';
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

      try {
        final worldmove = await _apiClient.get<PackageCatalog>(
          ApiEndpoints.mobileWorldmovePackages,
          queryParameters: const {'scope': 'all'},
          parser: PackageCatalog.fromWorldmoveResponse,
        );
        for (final package in worldmove.packages) {
          if (_isHiddenProvider(package)) continue;
          final key = '${package.provider}|${package.id}';
          if (seenIds.add(key)) externalPackages.add(package);
        }
      } catch (_) {}

      try {
        final manual = await _apiClient.get<PackageCatalog>(
          ApiEndpoints.manualCatalogProducts,
          parser: PackageCatalog.fromManualResponse,
        );
        for (final package in manual.packages) {
          if (_isHiddenProvider(package)) continue;
          final key = '${package.provider}|${package.id}';
          if (seenIds.add(key)) externalPackages.add(package);
        }
      } catch (_) {}

      for (final source in const [
        (ApiEndpoints.airhubCatalogSources, 'airhub', 'Vodafone'),
        (ApiEndpoints.flexnetCatalogSources, 'flexnet', 'Orange Big Data'),
        (ApiEndpoints.tgtCatalogSources, 'tgt', 'Orange Balkans'),
      ]) {
        final catalog = await _fetchFirstProviderSource(
          source.$1,
          provider: source.$2,
          displayProvider: source.$3,
        );
        for (final package in catalog.packages) {
          if (_isHiddenProvider(package) || !_providerPackageAllowed(package)) continue;
          final key = '${package.provider}|${package.id}';
          if (seenIds.add(key)) externalPackages.add(package);
        }
      }

      packages.addAll(await _applyCentralPricing(externalPackages));

      final term = normalizedSearch.toLowerCase();
      final filtered = packages.where((package) {
        if (_isHiddenProvider(package)) return false;
        if (normalizedDestination.isNotEmpty &&
            package.destinationKey.toLowerCase() != normalizedDestination.toLowerCase()) {
          return false;
        }
        if (normalizedType.isNotEmpty &&
            package.packageType.toLowerCase() != normalizedType.toLowerCase()) {
          return false;
        }
        if (term.isNotEmpty &&
            ![
              package.name,
              package.destination,
              package.displayProvider,
              package.provider,
              package.id,
              package.dataLabel,
              package.validityLabel,
            ].any((value) => value.toLowerCase().contains(term))) {
          return false;
        }
        return true;
      }).toList();

      final catalog = PackageCatalog(packages: filtered, hasMore: hasMore);
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

  Future<List<MobilePackage>> _applyCentralPricing(List<MobilePackage> packages) async {
    if (packages.isEmpty) return const [];
    const batchSize = 250;
    final pricedPackages = <MobilePackage>[];
    for (var start = 0; start < packages.length; start += batchSize) {
      final end = start + batchSize < packages.length ? start + batchSize : packages.length;
      final batch = packages.sublist(start, end);
      try {
        final pricedBatch = await _apiClient.post<List<MobilePackage>>(
          ApiEndpoints.pricingBatchPreview,
          data: {
            'items': batch.map((package) => {
              'provider': package.provider,
              'package_id': package.id,
              'provider_price': package.price,
              'country': package.destination,
              'region': package.destinationKey,
              'currency': package.currency,
            }).toList(),
          },
          parser: (response) {
            final root = Map<String, dynamic>.from(response as Map);
            final rows = root['data'];
            if (rows is! List) return const [];
            final priced = <MobilePackage>[];
            for (var index = 0; index < rows.length && index < batch.length; index++) {
              final row = rows[index];
              if (row is! Map) continue;
              final pricing = row['pricing'];
              if (pricing is! Map || pricing['is_price_visible'] != true) continue;
              final rawPrice = pricing['charge_amount'] ?? pricing['after_admin'] ?? pricing['final_customer_price'];
              final price = double.tryParse('$rawPrice');
              if (price != null) priced.add(batch[index].withPrice(price));
            }
            return priced;
          },
        );
        if (pricedBatch.isEmpty) {
          pricedPackages.addAll(batch);
        } else {
          final pricedById = <String, MobilePackage>{
            for (final item in pricedBatch) item.id: item,
          };
          pricedPackages.addAll(batch.map((item) => pricedById[item.id] ?? item));
        }
      } catch (_) {
        pricedPackages.addAll(batch);
      }
    }
    return pricedPackages;
  }

  Future<PackageCatalog> _fetchFirstProviderSource(
    List<String> paths, {
    required String provider,
    required String displayProvider,
  }) async {
    for (final path in paths) {
      try {
        final catalog = await _apiClient.get<PackageCatalog>(
          path,
          parser: (response) => PackageCatalog.fromProviderResponse(
            response,
            provider: provider,
            displayProvider: displayProvider,
          ),
        );
        if (catalog.packages.isNotEmpty) return catalog;
      } catch (_) {}
    }
    return const PackageCatalog(packages: [], hasMore: false);
  }

  bool _isHiddenProvider(MobilePackage package) {
    final provider = package.provider.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final display = package.displayProvider.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return provider == 'esimcard' || display == 'esimcard';
  }

  bool _providerPackageAllowed(MobilePackage package) {
    if (package.id.isEmpty) return false;
    if (package.provider != 'tgt') return true;
    return const {
      'E-185-SC-AU-EO1-T-30D/60D-1GB',
      'E-185-SC-AU-EO1-T-30D/60D-3GB',
      'E-185-SC-AU-EO1-T-30D/60D-5GB',
      'E-185-SC-AU-EO1-T-30D/60D-10GB',
      'E-185-SC-AU-EO1-T-30D/60D-20GB',
      'E-185-SC-AU-EO1-T-30D/60D-30GB',
      'E-185-SC-AU-EO1-T-30D/60D-50GB',
      'E-185-ES-AU-EO1-T-30D/60D-1GB',
      'E-185-ES-AU-EO1-T-30D/60D-3GB',
      'E-185-ES-AU-EO1-T-30D/60D-5GB',
      'E-185-ES-AU-EO1-T-30D/60D-10GB',
      'E-185-ES-AU-EO1-T-30D/60D-20GB',
      'E-185-ES-AU-EO1-T-30D/60D-30GB',
      'E-185-ES-AU-EO1-T-30D/60D-50GB',
      'E-185-SC-AU-EO1-T-CTM-60D/60D-20GB',
      'E-185-SC-AU-EO1-T-CTM-60D/60D-60GB',
      'E-185-ES-AU-EO1-T-CTM-60D/60D-20GB',
      'E-185-ES-AU-EO1-T-CTM-60D/60D-60GB',
    }.contains(package.id.toUpperCase());
  }
}
