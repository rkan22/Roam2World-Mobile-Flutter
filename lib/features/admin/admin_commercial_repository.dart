import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class AdminCommercialData {
  const AdminCommercialData({required this.pricing, required this.reports});

  final AdminPricingSnapshot pricing;
  final AdminReportsSnapshot reports;
}

class AdminPricingSnapshot {
  const AdminPricingSnapshot({
    required this.totalRules,
    required this.featuredRules,
    required this.activeRules,
    required this.items,
  });

  final int totalRules;
  final int featuredRules;
  final int activeRules;
  final List<AdminPricingItem> items;

  factory AdminPricingSnapshot.fromResponse(dynamic response) {
    final data = _dataMap(response);
    final rows = data['items'];
    return AdminPricingSnapshot(
      totalRules: _int(data['mobile_package_rules']),
      featuredRules: _int(data['featured_rules']),
      activeRules: _int(data['active_rules']),
      items: rows is List
          ? rows
              .whereType<Map>()
              .map((row) => AdminPricingItem.fromJson(
                    Map<String, dynamic>.from(row),
                  ))
              .toList(growable: false)
          : const [],
    );
  }
}

class AdminPricingItem {
  const AdminPricingItem({
    required this.id,
    required this.provider,
    required this.packageId,
    required this.packageName,
    required this.isActive,
    required this.isFeatured,
  });

  final int id;
  final String provider;
  final String packageId;
  final String packageName;
  final bool isActive;
  final bool isFeatured;

  factory AdminPricingItem.fromJson(Map<String, dynamic> json) =>
      AdminPricingItem(
        id: _int(json['id']),
        provider: (json['provider'] ?? '').toString(),
        packageId: (json['package_id'] ?? '').toString(),
        packageName: (json['package_name'] ?? 'Package').toString(),
        isActive: json['is_active'] == true,
        isFeatured: json['is_featured'] == true,
      );
}

class AdminReportsSnapshot {
  const AdminReportsSnapshot({
    required this.totalOrders,
    required this.completedOrders,
    required this.failedOrders,
    required this.totalSales,
    required this.currency,
    required this.totalResellers,
    required this.activeResellers,
    required this.totalDealers,
    required this.activeDealers,
  });

  final int totalOrders;
  final int completedOrders;
  final int failedOrders;
  final double totalSales;
  final String currency;
  final int totalResellers;
  final int activeResellers;
  final int totalDealers;
  final int activeDealers;

  factory AdminReportsSnapshot.fromResponse(dynamic response) {
    final data = _dataMap(response);
    final orders = _map(data['orders']);
    final revenue = _map(data['revenue']);
    final resellers = _map(data['resellers']);
    final dealers = _map(data['dealers']);
    return AdminReportsSnapshot(
      totalOrders: _int(orders['total']),
      completedOrders: _int(orders['completed']),
      failedOrders: _int(orders['failed']),
      totalSales: _double(revenue['total_sales']),
      currency: (revenue['currency'] ?? 'USD').toString(),
      totalResellers: _int(resellers['total']),
      activeResellers: _int(resellers['active']),
      totalDealers: _int(dealers['total']),
      activeDealers: _int(dealers['active']),
    );
  }
}

class AdminCommercialRepository {
  AdminCommercialRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AdminCommercialData> fetch() async {
    final results = await Future.wait<dynamic>([
      _apiClient.get<AdminPricingSnapshot>(
        ApiEndpoints.mobileAdminPricing,
        parser: AdminPricingSnapshot.fromResponse,
      ),
      _apiClient.get<AdminReportsSnapshot>(
        ApiEndpoints.mobileAdminReports,
        parser: AdminReportsSnapshot.fromResponse,
      ),
    ]);
    return AdminCommercialData(
      pricing: results[0] as AdminPricingSnapshot,
      reports: results[1] as AdminReportsSnapshot,
    );
  }
}

Map<String, dynamic> _dataMap(dynamic response) {
  final root = response is Map
      ? Map<String, dynamic>.from(response)
      : <String, dynamic>{};
  return _map(root['data'] ?? root);
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

int _int(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;

double _double(dynamic value) =>
    double.tryParse((value ?? 0).toString()) ?? 0;
