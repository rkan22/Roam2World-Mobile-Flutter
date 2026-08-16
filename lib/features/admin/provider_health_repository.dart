import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class ProviderHealthSummary {
  const ProviderHealthSummary({
    required this.status,
    required this.online,
    required this.degraded,
    required this.notConfigured,
    required this.routableCategories,
    required this.unroutableCategories,
    required this.categoriesUsingFallback,
  });

  final String status;
  final int online;
  final int degraded;
  final int notConfigured;
  final int routableCategories;
  final int unroutableCategories;
  final int categoriesUsingFallback;

  factory ProviderHealthSummary.fromJson(Map<String, dynamic> json) {
    int number(String key) => int.tryParse('${json[key] ?? 0}') ?? 0;
    return ProviderHealthSummary(
      status: '${json['status'] ?? ''}',
      online: number('online'),
      degraded: number('degraded'),
      notConfigured: number('not_configured'),
      routableCategories: number('routable_categories'),
      unroutableCategories: number('unroutable_categories'),
      categoriesUsingFallback: number('categories_using_fallback'),
    );
  }
}

class ProviderHealthItem {
  const ProviderHealthItem({
    required this.provider,
    required this.displayName,
    required this.status,
    required this.configured,
    required this.adapterReady,
    required this.supports,
    required this.liveCheckOk,
    required this.latencyMs,
    required this.error,
    required this.totalOrders,
    required this.failedOrders,
  });

  final String provider;
  final String displayName;
  final String status;
  final bool configured;
  final bool adapterReady;
  final List<String> supports;
  final bool? liveCheckOk;
  final int? latencyMs;
  final String error;
  final int totalOrders;
  final int failedOrders;

  factory ProviderHealthItem.fromJson(Map<String, dynamic> json) {
    final live = json['live'] is Map
        ? Map<String, dynamic>.from(json['live'] as Map)
        : const <String, dynamic>{};
    final stats = json['stats'] is Map
        ? Map<String, dynamic>.from(json['stats'] as Map)
        : const <String, dynamic>{};
    final supports = json['supports'] is List
        ? (json['supports'] as List).map((value) => '$value').toList()
        : const <String>[];
    return ProviderHealthItem(
      provider: '${json['provider'] ?? ''}',
      displayName: '${json['display_name'] ?? json['provider'] ?? ''}',
      status: '${json['status'] ?? ''}',
      configured: json['configured'] == true,
      adapterReady: json['adapter_ready'] == true,
      supports: supports,
      liveCheckOk: live['live_check_ok'] is bool
          ? live['live_check_ok'] as bool
          : null,
      latencyMs: int.tryParse('${live['latency_ms'] ?? ''}'),
      error: '${live['error'] ?? stats['last_error'] ?? ''}',
      totalOrders:
          int.tryParse(
            '${stats['total_orders'] ?? stats['total_records'] ?? 0}',
          ) ??
          0,
      failedOrders: int.tryParse('${stats['failed'] ?? 0}') ?? 0,
    );
  }
}

class ProviderRouteHealthItem {
  const ProviderRouteHealthItem({
    required this.category,
    required this.displayName,
    required this.healthStatus,
    required this.primaryProvider,
    required this.primaryOnline,
    required this.fallbackProviders,
    required this.fallbackOnline,
    required this.routable,
    required this.actionRequired,
  });

  final String category;
  final String displayName;
  final String healthStatus;
  final String primaryProvider;
  final bool primaryOnline;
  final List<String> fallbackProviders;
  final List<String> fallbackOnline;
  final bool routable;
  final List<String> actionRequired;

  factory ProviderRouteHealthItem.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) => json[key] is List
        ? (json[key] as List).map((value) => '$value').toList()
        : const <String>[];
    return ProviderRouteHealthItem(
      category: '${json['category'] ?? ''}',
      displayName: '${json['display_name'] ?? json['category'] ?? ''}',
      healthStatus: '${json['health_status'] ?? ''}',
      primaryProvider: '${json['primary_provider'] ?? ''}',
      primaryOnline: json['primary_online'] == true,
      fallbackProviders: strings('fallback_providers'),
      fallbackOnline: strings('fallback_online'),
      routable: json['routable'] == true,
      actionRequired: strings('action_required'),
    );
  }
}

class ProviderHealthData {
  const ProviderHealthData({
    required this.healthStatus,
    required this.liveCheck,
    required this.summary,
    required this.providers,
    required this.routes,
  });

  final String healthStatus;
  final bool liveCheck;
  final ProviderHealthSummary summary;
  final List<ProviderHealthItem> providers;
  final List<ProviderRouteHealthItem> routes;

  factory ProviderHealthData.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final summary = root['summary'] is Map
        ? Map<String, dynamic>.from(root['summary'] as Map)
        : const <String, dynamic>{};
    final providers = root['providers'] is List
        ? root['providers'] as List
        : const [];
    final routes = root['routes'] is List ? root['routes'] as List : const [];
    return ProviderHealthData(
      healthStatus: '${root['health_status'] ?? summary['status'] ?? ''}',
      liveCheck: root['live_check'] == true,
      summary: ProviderHealthSummary.fromJson(summary),
      providers: providers
          .whereType<Map>()
          .map(
            (item) =>
                ProviderHealthItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      routes: routes
          .whereType<Map>()
          .map(
            (item) => ProviderRouteHealthItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class ProviderHealthRepository {
  ProviderHealthRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ProviderHealthData> fetch({bool liveCheck = false}) {
    return _apiClient.get<ProviderHealthData>(
      ApiEndpoints.mobileB2BProviderHealth,
      queryParameters: {'live': liveCheck},
      parser: ProviderHealthData.fromResponse,
    );
  }
}
