class OrderHistory {
  const OrderHistory({required this.orders, required this.count});

  final List<MobileOrderSummary> orders;
  final int count;

  factory OrderHistory.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final rawOrders = data['orders'] ?? data['results'] ?? const [];
    return OrderHistory(
      orders: rawOrders is List
          ? rawOrders
              .whereType<Map>()
              .map((item) => MobileOrderSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      count: int.tryParse((data['count'] ?? 0).toString()) ?? 0,
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
    this.customerEmail = '',
    this.iccid = '',
    this.orderType = '',
    this.qrCode = '',
    this.activationCode = '',
  });

  final int id;
  final String orderNumber;
  final String packageName;
  final String customerName;
  final String customerEmail;
  final String status;
  final double amount;
  final String currency;
  final DateTime? createdAt;
  final int? esimId;
  final String iccid;
  final String orderType;
  final String qrCode;
  final String activationCode;

  factory MobileOrderSummary.fromJson(Map<String, dynamic> json) {
    final item = json['items'] is List && (json['items'] as List).isNotEmpty &&
            (json['items'] as List).first is Map
        ? Map<String, dynamic>.from((json['items'] as List).first as Map)
        : json['order_items'] is List && (json['order_items'] as List).isNotEmpty &&
                (json['order_items'] as List).first is Map
            ? Map<String, dynamic>.from((json['order_items'] as List).first as Map)
            : const <String, dynamic>{};
    final esim = json['esim'] is Map
        ? Map<String, dynamic>.from(json['esim'] as Map)
        : item['esim'] is Map
            ? Map<String, dynamic>.from(item['esim'] as Map)
            : const <String, dynamic>{};
    final customer = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : json['client'] is Map
            ? Map<String, dynamic>.from(json['client'] as Map)
            : const <String, dynamic>{};

    final rawAmount = json['total_amount'] ??
        json['charge_amount'] ??
        json['price'] ??
        json['amount'] ??
        item['total_price'] ??
        item['price'] ??
        0;
    final rawDate = json['created_at'] ?? json['created'] ?? json['order_date'];
    final rawOrderNumber = json['traveroam_order_reference'] ??
        json['order_number'] ??
        json['reference'] ??
        json['id'];
    final rawCustomerName = json['customer_name'] ??
        json['client_name'] ??
        json['delivery_recipient_name'] ??
        item['customer_name'] ??
        customer['full_name'] ??
        [customer['first_name'], customer['last_name']]
            .where((value) => value != null && value.toString().trim().isNotEmpty)
            .join(' ');

    return MobileOrderSummary(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      orderNumber: _ensureR2WReference(rawOrderNumber),
      packageName: json['package_name']?.toString() ??
          json['product_name']?.toString() ??
          json['bundle_name']?.toString() ??
          item['package_name']?.toString() ??
          item['product_name']?.toString() ??
          'eSIM package',
      customerName: rawCustomerName?.toString() ?? '',
      customerEmail: json['customer_email']?.toString() ??
          json['client_email']?.toString() ??
          json['delivery_email']?.toString() ??
          customer['email']?.toString() ??
          item['customer_email']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'pending',
      amount: double.tryParse(rawAmount.toString()) ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      createdAt: rawDate == null ? null : DateTime.tryParse(rawDate.toString()),
      esimId: int.tryParse((json['esim_id'] ?? esim['id'] ?? '').toString()),
      iccid: json['iccid']?.toString() ??
          json['esim_iccid']?.toString() ??
          json['sim_iccid']?.toString() ??
          item['iccid']?.toString() ??
          esim['iccid']?.toString() ??
          '',
      orderType: json['order_type']?.toString() ??
          json['product_type']?.toString() ??
          item['product_type']?.toString() ??
          'eSIM',
      qrCode: json['qr_code']?.toString() ??
          json['qrCode']?.toString() ??
          esim['qr_code']?.toString() ??
          esim['qrCode']?.toString() ??
          '',
      activationCode: json['activation_code']?.toString() ??
          json['activationCode']?.toString() ??
          esim['activation_code']?.toString() ??
          '',
    );
  }

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
  bool get hasInstallData => qrCode.isNotEmpty || activationCode.isNotEmpty;
}

String _ensureR2WReference(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';
  if (raw.toUpperCase().startsWith('R2W-')) return raw;
  final normalized = raw.replaceFirst(RegExp(r'^(?:ORDER[-_]?|#)', caseSensitive: false), '');
  return 'R2W-$normalized';
}
