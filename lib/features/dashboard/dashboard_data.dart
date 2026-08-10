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
      productName: json['product_name']?.toString() ?? 'eSIM package',
      status: json['status']?.toString() ?? 'pending',
      totalAmount: _toDouble(json['total_amount']),
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
  });

  final String role;
  final double balance;
  final String currency;
  final double todaySales;
  final double monthlySales;
  final int activeEsimCount;
  final int expiredEsimCount;
  final List<DashboardOrderSummary> recentOrders;

  DashboardData copyWith({
    double? balance,
    String? currency,
    List<DashboardOrderSummary>? recentOrders,
  }) {
    return DashboardData(
      role: role,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      todaySales: todaySales,
      monthlySales: monthlySales,
      activeEsimCount: activeEsimCount,
      expiredEsimCount: expiredEsimCount,
      recentOrders: recentOrders ?? this.recentOrders,
    );
  }

  factory DashboardData.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = Map<String, dynamic>.from(root['data'] as Map? ?? const {});
    final balanceValue = data['current_credit'] ?? data['current_balance'];
    final orders = data['recent_orders'] as List? ?? const [];

    return DashboardData(
      role: data['role']?.toString() ?? '',
      balance: _toDouble(balanceValue),
      currency: data['currency']?.toString() ?? 'USD',
      todaySales: _toDouble(data['today_sales']),
      monthlySales: _toDouble(data['monthly_sales']),
      activeEsimCount: _toInt(data['active_esim_count']),
      expiredEsimCount: _toInt(data['expired_esim_count']),
      recentOrders: orders
          .whereType<Map>()
          .map(
            (item) =>
                DashboardOrderSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }

  factory DashboardData.fromAdminResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = Map<String, dynamic>.from(root['data'] as Map? ?? const {});
    final metrics = Map<String, dynamic>.from(
      data['metrics'] as Map? ?? const {},
    );
    final revenue = Map<String, dynamic>.from(
      metrics['revenue'] as Map? ?? const {},
    );
    final salesOverview = Map<String, dynamic>.from(
      data['sales_overview'] as Map? ?? const {},
    );
    final orders = data['latest_orders'] as List? ?? const [];

    return DashboardData(
      role: 'Admin',
      balance: 0,
      currency: (salesOverview['currency'] ?? revenue['currency'] ?? 'USD')
          .toString(),
      todaySales: _toDouble(salesOverview['today_sales']),
      monthlySales: _toDouble(
        salesOverview['total_sales'] ?? revenue['total_sales'],
      ),
      activeEsimCount: _toInt(metrics['active_esim_count']),
      expiredEsimCount: _toInt(metrics['expired_esim_count']),
      recentOrders: orders
          .whereType<Map>()
          .map(
            (item) =>
                DashboardOrderSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }
}

double _toDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;

int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
