class SimCardPackage {
  const SimCardPackage({
    required this.id,
    required this.name,
    required this.destination,
    required this.price,
    required this.currency,
    required this.minimumQuantity,
    this.provider = '',
    this.category = 'sim_card',
  });

  final String id;
  final String name;
  final String destination;
  final double price;
  final String currency;
  final int minimumQuantity;
  final String provider;
  final String category;

  factory SimCardPackage.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['reseller_price'] ?? 0;
    return SimCardPackage(
      id: (json['productId'] ?? json['id'] ?? json['package_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? json['productName'] ?? 'SIM Card').toString(),
      destination: (json['destination'] ?? json['productRegion'] ?? 'Global').toString(),
      price: double.tryParse(rawPrice.toString()) ?? 0,
      currency: (json['currency'] ?? 'USD').toString(),
      minimumQuantity: int.tryParse((json['min_qty'] ?? 1).toString()) ?? 1,
      provider: (json['provider'] ?? '').toString(),
      category: (json['category'] ?? 'sim_card').toString(),
    );
  }
}

class SimCardCatalog {
  const SimCardCatalog({required this.packages, this.shipping = const {}});

  final List<SimCardPackage> packages;
  final Map<String, dynamic> shipping;

  factory SimCardCatalog.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final raw = root['packages'] ?? root['data'] ?? const [];
    final packages = raw is List
        ? raw
            .whereType<Map>()
            .map((item) => SimCardPackage.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <SimCardPackage>[];
    return SimCardCatalog(
      packages: packages,
      shipping: root['shipping'] is Map
          ? Map<String, dynamic>.from(root['shipping'] as Map)
          : const {},
    );
  }
}

class SimCardOrder {
  const SimCardOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.productName,
    required this.quantity,
    required this.totalAmount,
    required this.currency,
    this.providerOrderId,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String productName;
  final int quantity;
  final double totalAmount;
  final String currency;
  final String? providerOrderId;

  factory SimCardOrder.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['total_amount'] ?? json['total'] ?? 0;
    return SimCardOrder(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['order_number'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      productName: (json['product_name'] ?? json['name'] ?? 'SIM Card').toString(),
      quantity: int.tryParse((json['qty'] ?? json['quantity'] ?? 1).toString()) ?? 1,
      totalAmount: double.tryParse(rawAmount.toString()) ?? 0,
      currency: (json['currency'] ?? 'USD').toString(),
      providerOrderId: json['provider_order_id']?.toString(),
    );
  }
}

class SimCardOrderResult {
  const SimCardOrderResult({required this.order, this.shipping = const {}});

  final SimCardOrder order;
  final Map<String, dynamic> shipping;

  factory SimCardOrderResult.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final orderMap = root['order'] is Map
        ? Map<String, dynamic>.from(root['order'] as Map)
        : root;
    return SimCardOrderResult(
      order: SimCardOrder.fromJson(orderMap),
      shipping: root['shipping'] is Map
          ? Map<String, dynamic>.from(root['shipping'] as Map)
          : const {},
    );
  }
}
