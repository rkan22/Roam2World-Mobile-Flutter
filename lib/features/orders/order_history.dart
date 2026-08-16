import '../../shared/formatters/order_package_name_formatter.dart';

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
              .map(
                (item) => MobileOrderSummary.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : const <MobileOrderSummary>[];
    return OrderHistory(
      orders: orders,
      count:
          int.tryParse(
            (data['count'] ?? data['total'] ?? orders.length).toString(),
          ) ??
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
    final rawAmount =
        json['total_amount'] ?? json['price'] ?? json['amount'] ?? 0;
    final rawDate = json['created_at'] ?? json['created'] ?? json['order_date'];
    final rawPackageName =
        json['package_name']?.toString() ??
        json['product_name']?.toString() ??
        'eSIM package';
    return MobileOrderSummary(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      packageName: simplifyOrderPackageName(rawPackageName),
      customerName:
          json['customer_name']?.toString() ??
          json['delivery_recipient_name']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'pending',
      amount: double.tryParse(rawAmount.toString()) ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      createdAt: rawDate == null ? null : DateTime.tryParse(rawDate.toString()),
      esimId: int.tryParse((json['esim_id'] ?? '').toString()),
    );
  }

  MobileOrderSummary withCustomerName(String value) => MobileOrderSummary(
    id: id,
    orderNumber: orderNumber,
    packageName: packageName,
    customerName: value,
    status: status,
    amount: amount,
    currency: currency,
    createdAt: createdAt,
    esimId: esimId,
  );

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
}
