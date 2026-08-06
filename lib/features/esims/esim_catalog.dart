class EsimCatalog {
  const EsimCatalog({required this.esims, required this.count});

  final List<MobileEsim> esims;
  final int count;

  factory EsimCatalog.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final raw = data['esims'] ?? data['results'] ?? const [];
    final esims = raw is List
        ? raw
            .whereType<Map>()
            .map((item) => MobileEsim.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <MobileEsim>[];
    return EsimCatalog(
      esims: esims,
      count: int.tryParse((data['count'] ?? esims.length).toString()) ?? esims.length,
    );
  }
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

  factory MobileEsim.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) => value == null
        ? null
        : DateTime.tryParse(value.toString());

    return MobileEsim(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      iccid: json['iccid']?.toString() ?? '',
      provider: json['display_provider']?.toString() ??
          json['provider']?.toString() ??
          'Roam2World',
      packageName: json['package_name']?.toString() ??
          json['bundle_name']?.toString() ??
          json['plan_name']?.toString() ??
          'eSIM package',
      customerName: json['customer_name']?.toString() ??
          json['delivery_recipient_name']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'ready',
      installStatus: json['install_status']?.toString() ??
          json['profile_status']?.toString() ??
          '',
      activationCode: json['activation_code']?.toString() ?? '',
      qrCode: json['qr_code']?.toString() ?? '',
      expiresAt: parseDate(json['expires_at'] ?? json['expiry_date']),
    );
  }

  bool get isInstalled => installStatus.toLowerCase().contains('install');
  bool get hasQr => qrCode.isNotEmpty || activationCode.isNotEmpty;
}
