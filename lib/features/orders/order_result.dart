class MobileOrderResult {
  const MobileOrderResult({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.packageName,
    required this.totalAmount,
    required this.currency,
    required this.customerName,
    this.esimId,
    this.qrCode,
    this.activationCode,
    this.installAvailable = false,
  });

  final String orderId;
  final String orderNumber;
  final String status;
  final String packageName;
  final double totalAmount;
  final String currency;
  final String customerName;
  final String? esimId;
  final String? qrCode;
  final String? activationCode;
  final bool installAvailable;

  factory MobileOrderResult.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final order = data['order'] is Map
        ? Map<String, dynamic>.from(data['order'] as Map)
        : data;
    final customerFirst = data['customer_first_name']?.toString() ?? '';
    final customerLast = data['customer_last_name']?.toString() ?? '';
    final rawAmount = order['total_amount'] ?? data['total_amount'] ?? data['price'] ?? 0;

    return MobileOrderResult(
      orderId: (order['id'] ?? data['order_id'] ?? '').toString(),
      orderNumber: (order['order_number'] ?? data['order_number'] ?? '').toString(),
      status: (order['status'] ?? data['order_status'] ?? data['status'] ?? 'completed').toString(),
      packageName: (order['product_name'] ?? data['package_name'] ?? data['name'] ?? 'eSIM package').toString(),
      totalAmount: double.tryParse(rawAmount.toString()) ?? 0,
      currency: (data['currency'] ?? order['currency'] ?? 'USD').toString(),
      customerName: '$customerFirst $customerLast'.trim(),
      esimId: (data['esim_id'] ?? order['esim_id'])?.toString(),
      qrCode: data['qr_code']?.toString(),
      activationCode: data['activation_code']?.toString(),
      installAvailable: data['install_available'] == true,
    );
  }

  String get formattedTotal => '$currency ${totalAmount.toStringAsFixed(2)}';
}
