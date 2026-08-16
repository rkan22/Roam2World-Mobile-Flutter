class PricingRule {
  const PricingRule({
    required this.id,
    required this.provider,
    required this.packageId,
    required this.dealerId,
    required this.targetRole,
    required this.markupPercentage,
    required this.minMarkupPercentage,
    required this.maxMarkupPercentage,
    required this.priority,
    required this.isActive,
  });

  final int id;
  final String provider;
  final String packageId;
  final int? dealerId;
  final String targetRole;
  final double markupPercentage;
  final double? minMarkupPercentage;
  final double? maxMarkupPercentage;
  final int priority;
  final bool isActive;

  factory PricingRule.fromJson(Map<String, dynamic> json) => PricingRule(
    id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
    provider: json['provider']?.toString() ?? '',
    packageId: json['package_id']?.toString() ?? '',
    dealerId: int.tryParse((json['dealer'] ?? '').toString()),
    targetRole: (json['target_role'] ?? '').toString(),
    markupPercentage:
        double.tryParse((json['markup_percentage'] ?? 0).toString()) ?? 0,
    minMarkupPercentage: double.tryParse(
      (json['min_markup_percentage'] ?? '').toString(),
    ),
    maxMarkupPercentage: double.tryParse(
      (json['max_markup_percentage'] ?? '').toString(),
    ),
    priority: int.tryParse((json['priority'] ?? 0).toString()) ?? 0,
    isActive: json['is_active'] != false,
  );
}

List<PricingRule> pricingRulesFromResponse(dynamic response) {
  final root = response is Map
      ? Map<String, dynamic>.from(response)
      : <String, dynamic>{};
  final data = root['data'] ?? root;
  final raw = data is Map
      ? (data['results'] ?? data['data'] ?? const [])
      : data;
  return raw is List
      ? raw
            .whereType<Map>()
            .map(
              (item) => PricingRule.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
      : const [];
}
