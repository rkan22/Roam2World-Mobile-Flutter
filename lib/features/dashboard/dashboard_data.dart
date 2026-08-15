import '../../shared/formatters/order_package_name_formatter.dart';

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
      productName: simplifyOrderPackageName(
        json['product_name']?.toString() ??
            json['package_name']?.toString() ??
            'eSIM package',
      ),
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
    required this.totalEsimCount,
    required this.activeEsimCount,
    required this.expiredEsimCount,
    required this.recentOrders,
    this.period = '30d',
    this.grossProfit = 0,
    this.grossMarginPercent = 0,
    this.successfulOrders = 0,
    this.pricedOrders = 0,
    this.totalOrders = 0,
    this.customerCount = 0,
  });

  final String role;
  final double balance;
  final String currency;
  final double todaySales;
  final double monthlySales;
  final int totalEsimCount;
  final int activeEsimCount;
  final int expiredEsimCount;
  final List<DashboardOrderSummary> recentOrders;
  final String period;
  final double grossProfit;
  final double grossMarginPercent;
  final int successfulOrders;
  final int pricedOrders;
  final int totalOrders;
  final int customerCount;

  DashboardData copyWith({
    double? balance,
    String? currency,
    double? todaySales,
    double? monthlySales,
    int? totalEsimCount,
    int? activeEsimCount,
    int? expiredEsimCount,
    List<DashboardOrderSummary>? recentOrders,
    String? period,
    double? grossProfit,
    double? grossMarginPercent,
    int? successfulOrders,
    int? pricedOrders,
    int? totalOrders,
    int? customerCount,
  }) {
    return DashboardData(
      role: role,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      todaySales: todaySales ?? this.todaySales,
      monthlySales: monthlySales ?? this.monthlySales,
      totalEsimCount: totalEsimCount ?? this.totalEsimCount,
      activeEsimCount: activeEsimCount ?? this.activeEsimCount,
      expiredEsimCount: expiredEsimCount ?? this.expiredEsimCount,
      recentOrders: recentOrders ?? this.recentOrders,
      period: period ?? this.period,
      grossProfit: grossProfit ?? this.grossProfit,
      grossMarginPercent: grossMarginPercent ?? this.grossMarginPercent,
      successfulOrders: successfulOrders ?? this.successfulOrders,
      pricedOrders: pricedOrders ?? this.pricedOrders,
      totalOrders: totalOrders ?? this.totalOrders,
      customerCount: customerCount ?? this.customerCount,
    );
  }

  factory DashboardData.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = Map<String, dynamic>.from(root['data'] as Map? ?? const {});
    final metrics = _map(
      data['metrics'] ?? data['statistics'] ?? data['stats'],
    );
    final sales = _map(
      data['sales'] ?? data['sales_overview'] ?? metrics['sales'],
    );
    final esims = _map(data['esims'] ?? data['esim_stats'] ?? metrics['esims']);
    final wallet = _map(data['wallet']);
    final ordersMap = _map(data['orders']);
    final customers = _map(data['customers']);
    final balanceValue = _first([
      wallet['balance'],
      data['current_credit'],
      data['current_balance'],
    ]);
    final orderItems =
        ordersMap['recent'] as List? ?? data['recent_orders'] as List? ?? const [];
    final revenue = _first([
      sales['revenue'],
      data['total_sales'],
      data['monthly_sales'],
      data['totalSales'],
      data['monthlySales'],
      sales['total_sales'],
      sales['monthly_sales'],
    ]);

    return DashboardData(
      role: data['role']?.toString() ?? '',
      balance: _toDouble(balanceValue),
      currency: _first([
            wallet['currency'],
            data['currency'],
          ])?.toString() ??
          'USD',
      todaySales: _toDouble(
        _first([
          data['today_sales'],
          data['todaySales'],
          sales['today_sales'],
          sales['todaySales'],
        ]),
      ),
      monthlySales: _toDouble(revenue),
      totalEsimCount: _toInt(
        _first([
          esims['total'],
          data['total_esim_count'],
          data['total_esims'],
          data['totalEsims'],
          metrics['total_esims'],
          esims['total_esims'],
        ]),
      ),
      activeEsimCount: _toInt(
        _first([
          esims['active'],
          data['active_esim_count'],
          data['active_esims'],
          data['activeEsims'],
          metrics['active_esims'],
          esims['active_esims'],
        ]),
      ),
      expiredEsimCount: _toInt(
        _first([
          esims['expired'],
          data['expired_esim_count'],
          data['expired_esims'],
          data['expiredEsims'],
          metrics['expired_esims'],
          esims['expired_esims'],
        ]),
      ),
      recentOrders: orderItems
          .whereType<Map>()
          .map(
            (item) =>
                DashboardOrderSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      period: data['period']?.toString() ?? '30d',
      grossProfit: _toDouble(sales['gross_profit']),
      grossMarginPercent: _toDouble(sales['gross_margin_percent']),
      successfulOrders: _toInt(sales['successful_orders']),
      pricedOrders: _toInt(sales['priced_orders']),
      totalOrders: _toInt(ordersMap['total']),
      customerCount: _toInt(customers['total']),
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
      totalEsimCount: _toInt(
        metrics['total_esim_count'] ?? metrics['total_esims'],
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

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

dynamic _first(List<dynamic> values) {
  for (final value in values) {
    if (value != null && value.toString().trim().isNotEmpty) return value;
  }
  return null;
}
