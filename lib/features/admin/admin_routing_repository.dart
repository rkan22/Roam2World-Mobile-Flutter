import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class AdminRoutingRule {
  const AdminRoutingRule({
    required this.id,
    required this.category,
    required this.provider,
    required this.displayName,
    required this.priority,
    required this.isActive,
    required this.isPrimary,
    required this.allowFallback,
    required this.markupPercent,
    required this.resellerMarkupPercent,
    required this.dealerMarkupPercent,
    required this.minProfit,
  });

  final int id;
  final String category;
  final String provider;
  final String displayName;
  final int priority;
  final bool isActive;
  final bool isPrimary;
  final bool allowFallback;
  final double? markupPercent;
  final double? resellerMarkupPercent;
  final double? dealerMarkupPercent;
  final double? minProfit;

  factory AdminRoutingRule.fromJson(Map<String, dynamic> json) =>
      AdminRoutingRule(
        id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
        category: json['category']?.toString() ?? '',
        provider: json['provider']?.toString() ?? '',
        displayName: json['display_name']?.toString() ?? '',
        priority: int.tryParse((json['priority'] ?? 0).toString()) ?? 0,
        isActive: json['is_active'] == true,
        isPrimary: json['is_primary'] == true,
        allowFallback: json['allow_fallback'] == true,
        markupPercent: double.tryParse(
          (json['markup_percent'] ?? '').toString(),
        ),
        resellerMarkupPercent: double.tryParse(
          (json['reseller_markup_percent'] ?? '').toString(),
        ),
        dealerMarkupPercent: double.tryParse(
          (json['dealer_markup_percent'] ?? '').toString(),
        ),
        minProfit: double.tryParse((json['min_profit'] ?? '').toString()),
      );
}

class AdminRoutingRepository {
  AdminRoutingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AdminRoutingRule>> fetchRules() {
    return _apiClient.get<List<AdminRoutingRule>>(
      ApiEndpoints.mobileAdminRoutingRules,
      parser: (response) {
        if (response is! Map) return const [];
        final root = Map<String, dynamic>.from(response);
        final raw = root['data'];
        if (raw is! List) return const [];
        return raw
            .whereType<Map>()
            .map(
              (row) =>
                  AdminRoutingRule.fromJson(Map<String, dynamic>.from(row)),
            )
            .toList(growable: false);
      },
    );
  }

  Future<AdminRoutingRule> override({
    required String action,
    required AdminRoutingRule rule,
    String reason = 'Mobile admin override',
  }) {
    return _apiClient.post<AdminRoutingRule>(
      ApiEndpoints.mobileAdminRoutingOverride,
      data: {
        'action': action,
        'category': rule.category,
        'provider': rule.provider,
        'reason': reason,
      },
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final data = Map<String, dynamic>.from(root['data'] as Map);
        return AdminRoutingRule.fromJson(data);
      },
    );
  }
}
