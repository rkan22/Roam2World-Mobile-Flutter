import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/cache/timed_cache.dart';
import 'package_catalog.dart';

class PackagesRepository {
  PackagesRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static final Map<String, TimedCache<PackageCatalog>> _caches = {};
  static final ValueNotifier<int> catalogRevision = ValueNotifier<int>(0);
  final ApiClient _apiClient;
  bool lastFetchUsedStale = false;

  Future<PackageCatalog> fetchPackages({
    String? search,
    String? destination,
    String? packageType,
    int limit = 250,
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

      final externalCatalogsFuture = Future.wait<PackageCatalog>([
        _fetchWorldmoveCatalog(),
        _fetchManualCatalog(),
        _fetchFirstProviderSource(
          ApiEndpoints.airhubCatalogSources,
          provider: 'airhub',
          displayProvider: 'Vodafone',
        ),
        _fetchFirstProviderSource(
          ApiEndpoints.flexnetCatalogSources,
          provider: 'flexnet',
          displayProvider: 'Orange Big Data',
        ),
        _fetchFirstProviderSource(
          ApiEndpoints.tgtCatalogSources,
          provider: 'tgt',
          displayProvider: 'Orange Balkans',
        ),
      ]);

      while (hasMore && pageCount < 20) {
        final page = await _apiClient.get<PackageCatalog>(
          ApiEndpoints.mobilePackages,
          queryParameters: {'limit': limit, 'offset': offset},
          parser: PackageCatalog.fromResponse,
        );

        for (final package in page.packages) {
          // TGT catalog has a dedicated backend-authoritative endpoint.
          // Ignore stale or duplicated TGT rows from the unified endpoint.
          if (_isTgtProvider(package) ||
              _isHiddenProvider(package) ||
              !_providerPackageAllowed(package)) {
            continue;
          }
          final dedupeKey = package.id.isEmpty
              ? '${package.provider}|${package.name}|${package.destination}|${package.price}'
              : '${package.provider}|${package.id}';
          if (seenIds.add(dedupeKey)) {
            packages.add(package);
          }
        }

        hasMore = page.hasMore;
        if (!hasMore || page.packages.isEmpty) break;

        offset += page.packages.length;
        pageCount++;
      }

      final externalCatalogs = await externalCatalogsFuture;
      for (final catalog in externalCatalogs) {
        for (final package in catalog.packages) {
          if (_isHiddenProvider(package) || !_providerPackageAllowed(package)) {
            continue;
          }
          final key = '${package.provider}|${package.id}';
          if (seenIds.add(key)) externalPackages.add(package);
        }
      }

      packages.addAll(await _applyCentralPricing(externalPackages));

      final term = normalizedSearch.toLowerCase();
      final filtered =
          packages.where((package) {
            if (_isHiddenProvider(package) ||
                !_providerPackageAllowed(package)) {
              return false;
            }
            if (normalizedDestination.isNotEmpty &&
                package.destinationKey.toLowerCase() !=
                    normalizedDestination.toLowerCase()) {
              return false;
            }
            if (normalizedType.isNotEmpty &&
                package.packageType.toLowerCase() !=
                    normalizedType.toLowerCase()) {
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
          }).toList()..sort((a, b) {
            final aTurkey = a.operatorKey == 'turkey';
            final bTurkey = b.operatorKey == 'turkey';
            if (aTurkey != bTurkey) return aTurkey ? -1 : 1;

            final priceCompare = a.price.compareTo(b.price);
            if (priceCompare != 0) return priceCompare;

            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

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
    catalogRevision.value++;
  }

  Future<PackageCatalog> _fetchWorldmoveCatalog() async {
    try {
      return await _apiClient.get<PackageCatalog>(
        ApiEndpoints.mobileWorldmovePackages,
        queryParameters: const {'scope': 'all'},
        parser: PackageCatalog.fromWorldmoveResponse,
      );
    } catch (_) {
      return const PackageCatalog(packages: [], hasMore: false);
    }
  }

  Future<PackageCatalog> _fetchManualCatalog() async {
    try {
      return await _apiClient.get<PackageCatalog>(
        ApiEndpoints.manualCatalogProducts,
        parser: PackageCatalog.fromManualResponse,
      );
    } catch (_) {
      return const PackageCatalog(packages: [], hasMore: false);
    }
  }

  Future<List<MobilePackage>> _applyCentralPricing(
    List<MobilePackage> packages,
  ) async {
    if (packages.isEmpty) return const [];
    const batchSize = 250;
    final batches = <List<MobilePackage>>[];
    for (var start = 0; start < packages.length; start += batchSize) {
      final end = start + batchSize < packages.length
          ? start + batchSize
          : packages.length;
      batches.add(packages.sublist(start, end));
    }

    final pricedBatches = await Future.wait(batches.map(_priceBatch));
    return pricedBatches.expand((batch) => batch).toList(growable: false);
  }

  Future<List<MobilePackage>> _priceBatch(List<MobilePackage> batch) async {
    try {
      final pricedBatch = await _apiClient.post<List<MobilePackage>>(
        ApiEndpoints.pricingBatchPreview,
        data: {
          'items': batch
              .map(
                (package) => {
                  'provider': package.provider,
                  'package_id': package.id,
                  'provider_price': package.price,
                  'country': package.destination,
                  'region': package.destinationKey,
                  'currency': package.currency,
                },
              )
              .toList(),
        },
        parser: (response) {
          final root = Map<String, dynamic>.from(response as Map);
          final rows = root['data'];
          if (rows is! List) return const [];
          final priced = <MobilePackage>[];
          for (
            var index = 0;
            index < rows.length && index < batch.length;
            index++
          ) {
            final row = rows[index];
            if (row is! Map) continue;
            final pricing = row['pricing'];
            if (pricing is! Map || pricing['is_price_visible'] != true) {
              continue;
            }
            final rawPrice =
                pricing['charge_amount'] ??
                pricing['after_admin'] ??
                pricing['final_customer_price'];
            final price = double.tryParse('$rawPrice');
            if (price != null) priced.add(batch[index].withPrice(price));
          }
          return priced;
        },
      );
      final pricedById = <String, MobilePackage>{
        for (final item in pricedBatch) item.id: item,
      };
      // Keep unpriced packages visible, but zero their customer price so the
      // UI renders Contact Admin instead of leaking provider cost.
      return batch
          .map((item) => pricedById[item.id] ?? item.withPrice(0))
          .toList(growable: false);
    } catch (_) {
      return batch.map((item) => item.withPrice(0)).toList(growable: false);
    }
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

  bool _isTgtProvider(MobilePackage package) {
    final provider = package.provider.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return provider == 'tgt';
  }

  bool _isHiddenProvider(MobilePackage package) {
    final provider = package.provider.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final display = package.displayProvider.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return provider == 'esimcard' || display == 'esimcard';
  }

  bool _providerPackageAllowed(MobilePackage package) {
    // Provider-specific allow/block rules are enforced by the backend.
    // Keeping a second hard-coded TGT list here made valid live products
    // disappear whenever the provider catalog changed.
    return package.id.isNotEmpty;
  }
}
