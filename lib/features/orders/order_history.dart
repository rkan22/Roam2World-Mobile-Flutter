class OrderHistory {
  const OrderHistory({required this.orders, required this.count});

  final List<MobileOrderSummary> orders;
  final int count;

  factory OrderHistory.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final rawOrders =
        data['orders'] ?? data['results'] ?? data['items'] ?? const [];
    final orders = rawOrders is List
        ? rawOrders
            .whereType<Map>()
            .map((item) => MobileOrderSummary.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : const <MobileOrderSummary>[];
    return OrderHistory(
      orders: orders,
      count: int.tryParse((data['count'] ?? data['total'] ?? orders.length).toString()) ??
          orders.length,
    );
  }
}

class MobileOrderSummary {
  const MobileOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.packageName,
    required this.customerName,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.esimId,
  });

  final int id;
  final String orderNumber;
  final String packageName;
  final String customerName;
  final String status;
  final double amount;
  final String currency;
  final DateTime? createdAt;
  final int? esimId;

  factory MobileOrderSummary.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['total_amount'] ?? json['price'] ?? json['amount'] ?? 0;
    final rawDate = json['created_at'] ?? json['created'] ?? json['order_date'];
    final rawPackageName = json['package_name']?.toString() ??
        json['product_name']?.toString() ??
        'eSIM package';
    return MobileOrderSummary(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      packageName: simplifyOrderPackageName(rawPackageName),
      customerName: json['customer_name']?.toString() ??
          json['delivery_recipient_name']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'pending',
      amount: double.tryParse(rawAmount.toString()) ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      createdAt: rawDate == null ? null : DateTime.tryParse(rawDate.toString()),
      esimId: int.tryParse((json['esim_id'] ?? '').toString()),
    );
  }

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
}

String simplifyOrderPackageName(String value) {
  final raw = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (raw.isEmpty) return 'Package order';

  final dataMatch = RegExp(r'\b(\d+(?:\.\d+)?)\s*(GB|MB)\b', caseSensitive: false).firstMatch(raw);
  final daysMatch = RegExp(r'\b(\d{1,3})\s*(?:days?|d)\b', caseSensitive: false).firstMatch(raw);
  final regionMatch = RegExp(
    r'\b(Turkey|Türkiye|Turkiye|Europe|Balkans|Global|Asia|America|Spain|France|Italy|Germany)\b',
    caseSensitive: false,
  ).firstMatch(raw);

  if (dataMatch != null || daysMatch != null) {
    final parts = <String>[];
    if (regionMatch != null) {
      final region = regionMatch.group(1)!;
      parts.add(_normalizeRegion(region));
    }
    if (dataMatch != null) {
      parts.add('${dataMatch.group(1)}${dataMatch.group(2)!.toUpperCase()}');
    }
    if (daysMatch != null) {
      parts.add('${daysMatch.group(1)} Days');
    }
    return parts.join(' · ');
  }

  final simplified = raw
      .replaceFirst(RegExp(r'^\s*\[(?:e)?sim\]\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\((?:e0?\d+|[^)]*countries[^)]*)\)', caseSensitive: false), '')
      .replaceAll(
        RegExp(
          r'\b(?:eSIM|SIM Card|data-only|business(?:\s+pro)?(?:\s+plan)?|travel)\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'[|·_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return simplified.isEmpty ? 'Package order' : simplified;
}

String _normalizeRegion(String value) {
  final normalized = value.toLowerCase();
  if (normalized == 'turkiye' || normalized == 'türkiye') return 'Turkey';
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}
