import '../../shared/formatters/order_package_name_formatter.dart';

class DashboardSalesTrendPoint {
  const DashboardSalesTrendPoint({required this.label, required this.value});

  final String label;
  final double value;

  factory DashboardSalesTrendPoint.fromJson(Map<String, dynamic> json) {
    return DashboardSalesTrendPoint(
      label:
          _first([
            json['label'],
            json['date'],
            json['day'],
            json['period'],
          ])?.toString() ??
          '',
      value: _toDouble(
        _first([json['value'], json['revenue'], json['amount'], json['total']]),
      ),
    );
  }
}

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
    this.salesTrend = const [],
    this.period = '30d',
    this.grossProfit = 0,
    this.grossMarginPercent = 0,
    this.successfulOrders = 0,
    this.pricedOrders = 0,
    this.totalOrders = 0,
    this.customerCount = 0,
    this.resellerCount = 0,
    this.activeResellerCount = 0,
    this.dealerCount = 0,
    this.activeDealerCount = 0,
    this.pendingOrders = 0,
    this.completedOrders = 0,
    this.failedOrders = 0,
    this.pendingResellerWalletRequests = 0,
    this.pendingDealerWalletRequests = 0,
    this.pendingWalletRequests = 0,
    this.manualFulfillmentPending = 0,
    this.providerRetriesRequiringReview = 0,
    this.supportTicketsOpen = 0,
    this.availableBlankSims = 0,
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
  final List<DashboardSalesTrendPoint> salesTrend;
  final String period;
  final double grossProfit;
  final double grossMarginPercent;
  final int successfulOrders;
  final int pricedOrders;
  final int totalOrders;
  final int customerCount;
  final int resellerCount;
  final int activeResellerCount;
  final int dealerCount;
  final int activeDealerCount;
  final int pendingOrders;
  final int completedOrders;
  final int failedOrders;
  final int pendingResellerWalletRequests;
  final int pendingDealerWalletRequests;
  final int pendingWalletRequests;
  final int manualFulfillmentPending;
  final int providerRetriesRequiringReview;
  final int supportTicketsOpen;
  final int availableBlankSims;

  DashboardData copyWith({
    double? balance,
    String? currency,
    double? todaySales,
    double? monthlySales,
    int? totalEsimCount,
    int? activeEsimCount,
    int? expiredEsimCount,
    List<DashboardOrderSummary>? recentOrders,
    List<DashboardSalesTrendPoint>? salesTrend,
    String? period,
    double? grossProfit,
    double? grossMarginPercent,
    int? successfulOrders,
    int? pricedOrders,
    int? totalOrders,
    int? customerCount,
    int? resellerCount,
    int? activeResellerCount,
    int? dealerCount,
    int? activeDealerCount,
    int? pendingOrders,
    int? completedOrders,
    int? failedOrders,
    int? pendingResellerWalletRequests,
    int? pendingDealerWalletRequests,
    int? pendingWalletRequests,
    int? manualFulfillmentPending,
    int? providerRetriesRequiringReview,
    int? supportTicketsOpen,
    int? availableBlankSims,
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
      salesTrend: salesTrend ?? this.salesTrend,
      period: period ?? this.period,
      grossProfit: grossProfit ?? this.grossProfit,
      grossMarginPercent: grossMarginPercent ?? this.grossMarginPercent,
      successfulOrders: successfulOrders ?? this.successfulOrders,
      pricedOrders: pricedOrders ?? this.pricedOrders,
      totalOrders: totalOrders ?? this.totalOrders,
      customerCount: customerCount ?? this.customerCount,
      resellerCount: resellerCount ?? this.resellerCount,
      activeResellerCount: activeResellerCount ?? this.activeResellerCount,
      dealerCount: dealerCount ?? this.dealerCount,
      activeDealerCount: activeDealerCount ?? this.activeDealerCount,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      failedOrders: failedOrders ?? this.failedOrders,
      pendingResellerWalletRequests:
          pendingResellerWalletRequests ?? this.pendingResellerWalletRequests,
      pendingDealerWalletRequests:
          pendingDealerWalletRequests ?? this.pendingDealerWalletRequests,
      pendingWalletRequests:
          pendingWalletRequests ?? this.pendingWalletRequests,
      manualFulfillmentPending:
          manualFulfillmentPending ?? this.manualFulfillmentPending,
      providerRetriesRequiringReview:
          providerRetriesRequiringReview ?? this.providerRetriesRequiringReview,
      supportTicketsOpen: supportTicketsOpen ?? this.supportTicketsOpen,
      availableBlankSims: availableBlankSims ?? this.availableBlankSims,
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
        ordersMap['recent'] as List? ??
        data['recent_orders'] as List? ??
        const [];
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
      currency:
          _first([wallet['currency'], data['currency']])?.toString() ?? 'USD',
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
      salesTrend: _parseSalesTrend(
        _first([
          sales['series'],
          sales['trend'],
          data['sales_series'],
          data['revenue_series'],
          data['revenue_history'],
        ]),
      ),
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
    final kpis = _map(data['kpis']);
    final ordersByStatus = _map(data['orders_by_status']);
    final partnerPerformance = _map(data['partner_performance']);
    final dailyOperations = _map(data['daily_operations']);
    final resellerItems = partnerPerformance['resellers'] as List? ?? const [];
    final dealerItems = partnerPerformance['dealers'] as List? ?? const [];
    final orders = data['latest_orders'] as List? ?? const [];

    final pendingOrders =
        _toInt(ordersByStatus['pending']) +
        _toInt(ordersByStatus['confirmed']) +
        _toInt(ordersByStatus['processing']);

    return DashboardData(
      role: 'Admin',
      balance: 0,
      currency: data['currency']?.toString() ?? 'USD',
      todaySales: 0,
      monthlySales: _toDouble(kpis['revenue']),
      totalEsimCount: _toInt(kpis['active_esims']),
      activeEsimCount: _toInt(kpis['active_esims']),
      expiredEsimCount: 0,
      recentOrders: orders
          .whereType<Map>()
          .map(
            (item) =>
                DashboardOrderSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      salesTrend: _parseSalesTrend(
        _first([
          data['sales_series'],
          data['revenue_series'],
          data['revenue_history'],
          kpis['series'],
        ]),
      ),
      period: data['period']?.toString() ?? '30d',
      grossProfit: _toDouble(kpis['gross_profit']),
      grossMarginPercent: _toDouble(kpis['gross_margin_percent']),
      successfulOrders: _toInt(kpis['completed_orders']),
      pricedOrders: _toInt(kpis['total_orders']),
      totalOrders: _toInt(kpis['total_orders']),
      resellerCount: resellerItems.isNotEmpty
          ? resellerItems.length
          : _toInt(kpis['active_resellers']),
      activeResellerCount: _toInt(kpis['active_resellers']),
      dealerCount: dealerItems.isNotEmpty
          ? dealerItems.length
          : _toInt(kpis['active_dealers']),
      activeDealerCount: _toInt(kpis['active_dealers']),
      pendingOrders: pendingOrders,
      completedOrders: _toInt(
        ordersByStatus['completed'] ?? kpis['completed_orders'],
      ),
      failedOrders: _toInt(ordersByStatus['failed']),
      pendingWalletRequests: _toInt(dailyOperations['wallet_requests_pending']),
      manualFulfillmentPending: _toInt(
        dailyOperations['manual_fulfillment_pending'],
      ),
      providerRetriesRequiringReview: _toInt(
        dailyOperations['provider_retries_requiring_review'],
      ),
      supportTicketsOpen: _toInt(dailyOperations['support_tickets_open']),
      availableBlankSims: _toInt(dailyOperations['available_blank_sims']),
    );
  }
}

List<DashboardSalesTrendPoint> _parseSalesTrend(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) =>
            DashboardSalesTrendPoint.fromJson(Map<String, dynamic>.from(item)),
      )
      .where((point) => point.label.isNotEmpty)
      .toList(growable: false);
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
