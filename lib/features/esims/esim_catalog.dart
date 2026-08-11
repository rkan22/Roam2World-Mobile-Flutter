class EsimCatalog {
  const EsimCatalog({required this.esims, required this.count});

  final List<MobileEsim> esims;
  final int count;

  factory EsimCatalog.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final nested = root['data'];
    final data = nested is Map ? Map<String, dynamic>.from(nested) : root;
    final raw = nested is List
        ? nested
        : data['esims'] ?? data['results'] ?? data['items'] ?? const [];
    final esims = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) => MobileEsim.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <MobileEsim>[];
    return EsimCatalog(
      esims: esims,
      count:
          int.tryParse((data['count'] ?? esims.length).toString()) ??
          esims.length,
    );
  }
}

class MobileRenewalOption {
  const MobileRenewalOption({
    required this.provider,
    required this.displayProvider,
    required this.operation,
    required this.productCode,
    required this.dataGb,
    required this.validityDays,
    required this.price,
    required this.currency,
    required this.adminMarkupPercent,
    required this.resellerMarkupPercent,
    required this.dealerMarkupPercent,
  });

  final String provider;
  final String displayProvider;
  final String operation;
  final String productCode;
  final int dataGb;
  final int validityDays;
  final double price;
  final String currency;
  final double adminMarkupPercent;
  final double resellerMarkupPercent;
  final double dealerMarkupPercent;

  factory MobileRenewalOption.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] is Map
        ? Map<String, dynamic>.from(json['pricing'] as Map)
        : const <String, dynamic>{};
    double number(dynamic value) => double.tryParse('$value') ?? 0;

    return MobileRenewalOption(
      provider: '${json['provider'] ?? ''}',
      displayProvider:
          '${json['display_provider'] ?? json['provider'] ?? 'Roam2World'}',
      operation: '${json['operation'] ?? 'renew'}',
      productCode:
          '${json['product_code'] ?? json['plan_code'] ?? json['package_id'] ?? ''}',
      dataGb: number(json['data_gb']).round(),
      validityDays: number(json['validity_days']).round(),
      price: number(json['price']),
      currency: '${json['currency'] ?? 'USD'}',
      adminMarkupPercent: number(pricing['admin_markup_percent']),
      resellerMarkupPercent: number(pricing['reseller_markup_percent']),
      dealerMarkupPercent: number(pricing['dealer_markup_percent']),
    );
  }

  String get formattedPrice => '$currency ${price.toStringAsFixed(2)}';
}

class MobileEsim {
  const MobileEsim({
    required this.id,
    required this.iccid,
    required this.provider,
    required this.packageName,
    required this.customerName,
    required this.status,
    required this.installStatus,
    required this.activationCode,
    required this.qrCode,
    required this.expiresAt,
    this.actualProvider = '',
    this.packageId = '',
    this.providerOrderId = '',
  });

  final int id;
  final String iccid;
  final String provider;
  final String packageName;
  final String customerName;
  final String status;
  final String installStatus;
  final String activationCode;
  final String qrCode;
  final DateTime? expiresAt;
  final String actualProvider;
  final String packageId;
  final String providerOrderId;

  factory MobileEsim.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());

    return MobileEsim(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      iccid: json['iccid']?.toString() ?? '',
      provider:
          json['display_provider']?.toString() ??
          json['provider']?.toString() ??
          'Roam2World',
      packageName:
          json['package_name']?.toString() ??
          json['bundle_name']?.toString() ??
          json['plan_name']?.toString() ??
          'eSIM package',
      customerName:
          json['customer_name']?.toString() ??
          json['delivery_recipient_name']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'ready',
      installStatus:
          json['install_status']?.toString() ??
          json['profile_status']?.toString() ??
          '',
      activationCode: json['activation_code']?.toString() ?? '',
      qrCode: json['qr_code']?.toString() ?? '',
      expiresAt: parseDate(json['expires_at'] ?? json['expiry_date']),
      actualProvider:
          json['actual_provider']?.toString() ??
          json['provider']?.toString() ??
          '',
      packageId:
          json['package_id']?.toString() ??
          json['product_id']?.toString() ??
          json['wmproductId']?.toString() ??
          '',
      providerOrderId:
          json['provider_order_id']?.toString() ??
          json['order_id']?.toString() ??
          '',
    );
  }

  bool get isInstalled => installStatus.toLowerCase().contains('install');
  bool get hasQr => qrCode.isNotEmpty || activationCode.isNotEmpty;
  String get providerKey => actualProvider.isEmpty ? provider : actualProvider;
}
