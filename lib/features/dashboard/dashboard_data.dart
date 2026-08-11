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
      productName: _friendlyProductName(
        json['product_name']?.toString() ?? 'eSIM package',
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

  DashboardData copyWith({
    double? balance,
    String? currency,
    double? todaySales,
    double? monthlySales,
    int? totalEsimCount,
    int? activeEsimCount,
    int? expiredEsimCount,
    List<DashboardOrderSummary>? recentOrders,
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
    );
  }

  factory DashboardData.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = Map<String, dynamic>.from(root['data'] as Map? ?? const {});
    final metrics = _map(
      data['metrics'] ?? data['statistics'] ?? data['stats'],
    );
    final sales = _map(data['sales_overview'] ?? metrics['sales']);
    final esims = _map(data['esim_stats'] ?? metrics['esims']);
    final balanceValue = data['current_credit'] ?? data['current_balance'];
    final orders = data['recent_orders'] as List? ?? const [];

    return DashboardData(
      role: data['role']?.toString() ?? '',
      balance: _toDouble(balanceValue),
      currency: data['currency']?.toString() ?? 'USD',
      todaySales: _toDouble(
        _first([
          data['today_sales'],
          data['todaySales'],
          sales['today_sales'],
          sales['todaySales'],
        ]),
      ),
      monthlySales: _toDouble(
        _first([
          data['total_sales'],
          data['monthly_sales'],
          data['totalSales'],
          data['monthlySales'],
          sales['total_sales'],
          sales['monthly_sales'],
        ]),
      ),
      totalEsimCount: _toInt(
        _first([
          data['total_esim_count'],
          data['total_esims'],
          data['totalEsims'],
          metrics['total_esims'],
          esims['total'],
          esims['total_esims'],
        ]),
      ),
      activeEsimCount: _toInt(
        _first([
          data['active_esim_count'],
          data['active_esims'],
          data['activeEsims'],
          metrics['active_esims'],
          esims['active'],
          esims['active_esims'],
        ]),
      ),
      expiredEsimCount: _toInt(
        _first([
          data['expired_esim_count'],
          data['expired_esims'],
          data['expiredEsims'],
          metrics['expired_esims'],
          esims['expired'],
          esims['expired_esims'],
        ]),
      ),
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

String _friendlyProductName(String raw) {
  final value = raw.trim();
  final upper = value.toUpperCase();
  var data = RegExp(
    r'(\d+)\s*GB',
    caseSensitive: false,
  ).firstMatch(value)?.group(1);
  final days = RegExp(
    r'(\d+)\s*(?:D|DAYS?)',
    caseSensitive: false,
  ).firstMatch(value)?.group(1);
  if (upper.contains('WM-E-J1-VDFES-XXL')) {
    data = '60';
  } else if (upper.contains('WM-E-J1-VDFES-XL')) {
    data = '45';
  } else if (upper.contains('WM-E-J1-VDFES-M')) {
    data = '25';
  } else if (upper.contains('WM-E-J1-WLD-O-MINI-30D')) {
    data = '3';
  } else if (upper.contains('WM-E-J1-WLD-O-14D')) {
    data = '20';
  }
  if (upper.contains('WM-')) {
    final destination = upper.contains('WM-TR-')
        ? 'Turkey'
        : upper.contains('WM-E-J1-WLD-')
        ? 'Global'
        : 'Europe';
    return [
      destination,
      if (data != null) '${data}GB',
      if (days != null) '$days Days',
    ].join(' ');
  }
  if (upper.contains('E-185-') || upper.contains('E-184-')) {
    final type = upper.contains('-SC-') ? 'SIM Card' : 'eSIM';
    return [
      'Orange Balkans $type',
      if (data != null) '${data}GB',
      if (days != null) '$days Days',
    ].join(' ');
  }
  if (upper.contains('BIG DATA') && data != null) {
    return 'Orange Big Data ${upper.contains('SIM') ? 'SIM ' : ''}${data}GB';
  }
  if (value.toLowerCase().startsWith('[esim]')) {
    return value
        .replaceFirst(RegExp(r'^\[esim\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-_]'), ' ')
        .trim();
  }
  if (data != null && days != null && upper.contains('128K')) {
    return 'Europe ${data}GB $days Days';
  }
  return value;
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

dynamic _first(List<dynamic> values) {
  for (final value in values) {
    if (value != null && value.toString().trim().isNotEmpty) return value;
  }
  return null;
}
