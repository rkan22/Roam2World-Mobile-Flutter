class DashboardOrderSummary {
  const DashboardOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.productName,
    required this.status,
    required this.totalAmount,
    this.createdAt,
  });

  final int? id;
  final String orderNumber;
  final String productName;
  final String status;
  final double totalAmount;
  final DateTime? createdAt;

  factory DashboardOrderSummary.fromJson(Map<String, dynamic> json) {
    return DashboardOrderSummary(
      id: int.tryParse(json['id']?.toString() ?? ''),
      orderNumber: json['order_number']?.toString() ?? '',
      productName: json['product_name']?.toString() ??
          json['package_name']?.toString() ??
          'eSIM package',
      status: json['status']?.toString() ?? 'pending',
      totalAmount: _toDouble(json['total_amount'] ?? json['amount']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.role,
    required this.balance,
    required this.currency,
    required this.todaySales,
    required this.monthlySales,
    required this.activeEsimCount,
    required this.expiredEsimCount,
    required this.recentOrders,
    this.revenue,
    this.grossProfit,
    this.grossMarginPercent,
    this.successfulOrders,
    this.totalCustomers,
  });

  final String role;
  final double balance;
  final String currency;
  final double todaySales;
  final double monthlySales;
  final int activeEsimCount;
  final int expiredEsimCount;
  final List<DashboardOrderSummary> recentOrders;

  /// Optional richer B2B metrics. These are only populated when the API
  /// actually returns them; the UI must not fabricate fallback values.
  final double? revenue;
  final double? grossProfit;
  final double? grossMarginPercent;
  final int? successfulOrders;
  final int? totalCustomers;

  factory DashboardData.fromResponse(dynamic response) {
    final root = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;

    final wallet = _map(data['wallet']);
    final sales = _map(data['sales']);
    final customers = _map(data['customers']);
    final esims = _map(data['esims']);
    final ordersNode = _map(data['orders']);

    final balanceValue = data['current_credit'] ??
        data['current_balance'] ??
        wallet['balance'];

    final rawOrders = data['recent_orders'] is List
        ? data['recent_orders'] as List
        : ordersNode['recent'] is List
            ? ordersNode['recent'] as List
            : const [];

    return DashboardData(
      role: data['role']?.toString() ?? '',
      balance: _toDouble(balanceValue),
      currency: data['currency']?.toString() ??
          wallet['currency']?.toString() ??
          'USD',
      todaySales: _toDouble(data['today_sales']),
      monthlySales: _toDouble(data['monthly_sales']),
      activeEsimCount: _toInt(data['active_esim_count'] ?? esims['active']),
      expiredEsimCount: _toInt(data['expired_esim_count'] ?? esims['expired']),
      revenue: _optionalDouble(sales, 'revenue'),
      grossProfit: _optionalDouble(sales, 'gross_profit'),
      grossMarginPercent: _optionalDouble(sales, 'gross_margin_percent'),
      successfulOrders: _optionalInt(sales, 'successful_orders'),
      totalCustomers: _optionalInt(customers, 'total'),
      recentOrders: rawOrders
          .whereType<Map>()
          .map(
            (item) => DashboardOrderSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

double _toDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;

int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

double? _optionalDouble(Map<String, dynamic> source, String key) {
  if (!source.containsKey(key) || source[key] == null) return null;
  return double.tryParse(source[key].toString());
}

int? _optionalInt(Map<String, dynamic> source, String key) {
  if (!source.containsKey(key) || source[key] == null) return null;
  return int.tryParse(source[key].toString());
}
