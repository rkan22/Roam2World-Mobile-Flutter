class OperationsData {
  const OperationsData({
    required this.failedOrders,
    required this.logs,
    required this.auditEvents,
  });

  final List<FailedOrderItem> failedOrders;
  final List<OperationLogItem> logs;
  final List<AuditEventItem> auditEvents;
}

class FailedOrderItem {
  const FailedOrderItem({
    required this.id,
    required this.provider,
    required this.orderNumber,
    required this.customer,
    required this.packageName,
    required this.status,
    required this.error,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String provider;
  final String orderNumber;
  final String customer;
  final String packageName;
  final String status;
  final String error;
  final double amount;
  final String currency;
  final DateTime? createdAt;

  factory FailedOrderItem.fromJson(Map<String, dynamic> json) => FailedOrderItem(
        id: (json['id'] ?? json['order_id'] ?? json['reference'] ?? '').toString(),
        provider: _providerLabel(json['provider'] ?? json['provider_name'] ?? json['operator']),
        orderNumber: (json['order_no'] ?? json['order_number'] ?? json['reference'] ?? json['id'] ?? '').toString(),
        customer: (json['client_name'] ?? json['customer_name'] ?? json['user_name'] ?? json['email'] ?? '').toString(),
        packageName: (json['package_name'] ?? json['plan_name'] ?? json['product_name'] ?? json['name'] ?? 'Package').toString(),
        status: (json['status'] ?? json['state'] ?? 'failed').toString(),
        error: (json['error'] ?? json['error_message'] ?? json['message'] ?? json['failure_reason'] ?? 'Needs operations review').toString(),
        amount: double.tryParse((json['amount'] ?? json['total_price'] ?? json['sale_price'] ?? json['price'] ?? 0).toString()) ?? 0,
        currency: (json['currency'] ?? 'USD').toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? json['created'] ?? json['date'] ?? '').toString()),
      );

  String get priority {
    final text = '$status $error'.toLowerCase();
    if (text.contains('payment') || text.contains('wallet')) return 'Finance';
    if (text.contains('qr')) return 'QR';
    if (text.contains('renew') || text.contains('top')) return 'Renewal';
    return 'Provider';
  }
}

class OperationLogItem {
  const OperationLogItem({
    required this.id,
    required this.type,
    required this.provider,
    required this.endpoint,
    required this.method,
    required this.statusCode,
    required this.durationMs,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String provider;
  final String endpoint;
  final String method;
  final int statusCode;
  final int durationMs;
  final String message;
  final DateTime? createdAt;

  factory OperationLogItem.fromJson(Map<String, dynamic> json, String source) => OperationLogItem(
        id: (json['id'] ?? json['request_id'] ?? json['event_id'] ?? '').toString(),
        type: (json['type'] ?? json['event_type'] ?? source).toString(),
        provider: _providerLabel(json['provider'] ?? json['provider_name'] ?? json['operator']),
        endpoint: (json['endpoint'] ?? json['path'] ?? json['url'] ?? json['callback_url'] ?? '').toString(),
        method: (json['method'] ?? json['http_method'] ?? (source == 'Webhook' ? 'POST' : 'GET')).toString(),
        statusCode: int.tryParse((json['status'] ?? json['status_code'] ?? json['response_status'] ?? json['code'] ?? 0).toString()) ?? 0,
        durationMs: int.tryParse((json['duration_ms'] ?? json['latency_ms'] ?? json['response_time_ms'] ?? 0).toString()) ?? 0,
        message: (json['message'] ?? json['error'] ?? json['description'] ?? json['detail'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? json['timestamp'] ?? json['date'] ?? '').toString()),
      );

  bool get needsReview => statusCode == 0 || statusCode >= 400;
}

class AuditEventItem {
  const AuditEventItem({
    required this.id,
    required this.actor,
    required this.action,
    required this.target,
    required this.source,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String actor;
  final String action;
  final String target;
  final String source;
  final String description;
  final DateTime? createdAt;

  factory AuditEventItem.fromJson(Map<String, dynamic> json, {String source = 'audit'}) => AuditEventItem(
        id: (json['id'] ?? '${json['created_at'] ?? ''}-${json['action'] ?? ''}').toString(),
        actor: (json['actor_name'] ?? json['user_name'] ?? json['reseller_name'] ?? json['dealer_name'] ?? (json['user'] is Map ? (json['user'] as Map)['email'] : null) ?? json['email'] ?? 'System').toString(),
        action: (json['action'] ?? json['event'] ?? json['type'] ?? json['transaction_type'] ?? json['method'] ?? 'activity').toString(),
        target: (json['target'] ?? json['resource'] ?? json['object_type'] ?? json['provider'] ?? json['reference'] ?? json['id'] ?? 'Platform').toString(),
        source: (json['_source'] ?? json['source'] ?? json['category'] ?? source).toString(),
        description: (json['description'] ?? json['message'] ?? json['note'] ?? json['notes'] ?? json['detail'] ?? json['status'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? json['timestamp'] ?? json['date'] ?? json['created'] ?? '').toString()),
      );
}

String _providerLabel(dynamic value) {
  final raw = (value ?? '').toString();
  final key = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (key.contains('airhub') || key.contains('vodafone')) return 'Vodafone';
  if (key.contains('worldmove') || key.contains('orangeeurope')) return 'Orange Europe';
  if (key.contains('flexnet') || key.contains('bigdata')) return 'Orange Big Data';
  if (key.contains('tgt') || key.contains('tsim') || key.contains('balkan')) return 'Orange Balkans';
  return raw.isEmpty ? 'System' : raw;
}
