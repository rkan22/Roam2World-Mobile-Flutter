class AdminWhatsAppData {
  const AdminWhatsAppData({
    required this.connection,
    required this.delivery,
    required this.templates,
    required this.catalog,
    required this.manualApprovals,
  });

  final WhatsAppConnection connection;
  final Map<String, int> delivery;
  final List<WhatsAppTemplateSummary> templates;
  final List<WhatsAppCatalogItem> catalog;
  final List<WhatsAppManualApproval> manualApprovals;

  factory AdminWhatsAppData.fromResponse(dynamic response) {
    final root = response is Map
        ? Map<String, dynamic>.from(response)
        : const <String, dynamic>{};
    return AdminWhatsAppData(
      connection: WhatsAppConnection.fromJson(_map(root['connection'])),
      delivery: _map(
        root['delivery'],
      ).map((key, value) => MapEntry(key, _int(value))),
      templates: _rows(
        root['templates'],
      ).map(WhatsAppTemplateSummary.fromJson).toList(growable: false),
      catalog: _rows(
        root['catalog'],
      ).map(WhatsAppCatalogItem.fromJson).toList(growable: false),
      manualApprovals: _rows(
        root['manual_approvals'],
      ).map(WhatsAppManualApproval.fromJson).toList(growable: false),
    );
  }
}

class WhatsAppConnection {
  const WhatsAppConnection({
    required this.enabled,
    required this.phoneConfigured,
    required this.tokenConfigured,
    required this.webhookConfigured,
  });

  final bool enabled;
  final bool phoneConfigured;
  final bool tokenConfigured;
  final bool webhookConfigured;

  bool get isReady =>
      enabled && phoneConfigured && tokenConfigured && webhookConfigured;

  factory WhatsAppConnection.fromJson(Map<String, dynamic> json) =>
      WhatsAppConnection(
        enabled: json['enabled'] == true,
        phoneConfigured: json['phone_number_configured'] == true,
        tokenConfigured: json['access_token_configured'] == true,
        webhookConfigured: json['webhook_secret_configured'] == true,
      );
}

class WhatsAppTemplateSummary {
  const WhatsAppTemplateSummary({
    required this.event,
    required this.name,
    required this.language,
    required this.status,
    required this.total,
  });

  final String event;
  final String name;
  final String language;
  final String status;
  final int total;

  factory WhatsAppTemplateSummary.fromJson(Map<String, dynamic> json) =>
      WhatsAppTemplateSummary(
        event: (json['event'] ?? '').toString(),
        name: (json['template_name'] ?? '').toString(),
        language: (json['language'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        total: _int(json['total']),
      );
}

class WhatsAppCatalogItem {
  const WhatsAppCatalogItem({
    required this.id,
    required this.provider,
    required this.packageId,
    required this.packageName,
    required this.customerPrice,
    required this.supplierPrice,
    required this.pricingStatus,
    required this.featured,
  });

  final int? id;
  final String provider;
  final String packageId;
  final String packageName;
  final double? customerPrice;
  final double? supplierPrice;
  final String pricingStatus;
  final bool featured;

  factory WhatsAppCatalogItem.fromJson(
    Map<String, dynamic> json,
  ) => WhatsAppCatalogItem(
    id: int.tryParse(json['id']?.toString() ?? ''),
    provider: (json['provider'] ?? '').toString(),
    packageId: (json['package_id'] ?? '').toString(),
    packageName: (json['package_name'] ?? 'Package').toString(),
    customerPrice: double.tryParse(json['customer_price']?.toString() ?? ''),
    supplierPrice: double.tryParse(json['supplier_price']?.toString() ?? ''),
    pricingStatus: (json['pricing_status'] ?? '').toString(),
    featured: json['featured'] == true,
  );

  Map<String, dynamic> toUpdateJson({required bool featured}) => {
    if (id != null) 'id': id,
    'provider': provider,
    'package_id': packageId,
    'package_name': packageName,
    'featured': featured,
  };
}

class WhatsAppManualApproval {
  const WhatsAppManualApproval({
    required this.id,
    required this.operation,
    required this.packageName,
    required this.provider,
    required this.customerPhone,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  final int id;
  final String operation;
  final String packageName;
  final String provider;
  final String customerPhone;
  final double amount;
  final String currency;
  final DateTime? createdAt;

  factory WhatsAppManualApproval.fromJson(Map<String, dynamic> json) =>
      WhatsAppManualApproval(
        id: _int(json['id']),
        operation: (json['operation'] ?? '').toString(),
        packageName: (json['package_name'] ?? '').toString(),
        provider: (json['provider'] ?? '').toString(),
        customerPhone: (json['customer_phone'] ?? '').toString(),
        amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
        currency: (json['currency'] ?? 'USD').toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _rows(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false)
    : const [];

int _int(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
