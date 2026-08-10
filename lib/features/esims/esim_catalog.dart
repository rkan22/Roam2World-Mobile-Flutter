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
    required this.lineType,
    required this.dataLabel,
    required this.validityLabel,
    required this.smdpAddress,
    required this.matchingId,
    required this.usageBytes,
    required this.totalBytes,
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
  final String lineType;
  final String dataLabel;
  final String validityLabel;
  final String smdpAddress;
  final String matchingId;
  final double? usageBytes;
  final double? totalBytes;

  factory MobileEsim.fromJson(Map<String, dynamic> json) {
    final details = json['bundle_details'] is Map
        ? Map<String, dynamic>.from(json['bundle_details'] as Map)
        : const <String, dynamic>{};
    final package = json['package'] is Map
        ? Map<String, dynamic>.from(json['package'] as Map)
        : const <String, dynamic>{};
    final plan = json['plan'] is Map
        ? Map<String, dynamic>.from(json['plan'] as Map)
        : const <String, dynamic>{};

    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());

    String firstText(List<dynamic> values, [String fallback = '']) {
      for (final value in values) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return fallback;
    }

    String normalizeData(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return '';
      final text = value.toString().trim();
      if (RegExp(r'(gb|mb|tb)', caseSensitive: false).hasMatch(text)) return text;
      return '$text GB';
    }

    String normalizeValidity(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return '';
      final text = value.toString().trim();
      if (text.toLowerCase().contains('day')) return text;
      return '$text Days';
    }

    final explicitType = firstText([
      json['line_type'],
      json['product_type'],
      json['sim_type'],
      details['line_type'],
      details['product_type'],
      details['type'],
    ]).toLowerCase();
    final physical = json['is_physical_sim'] == true ||
        details['is_physical_sim'] == true ||
        explicitType.contains('physical') ||
        ['sim', 'simcard', 'sim_card'].contains(explicitType);

    final used = _nullableDouble(
      json['usage_bytes'] ??
          json['used_bytes'] ??
          json['data_used_bytes'] ??
          details['usage_bytes'] ??
          details['used_bytes'],
    );
    final total = _nullableDouble(
      json['total_bytes'] ??
          json['data_total_bytes'] ??
          details['total_bytes'] ??
          details['data_total_bytes'],
    );

    return MobileEsim(
      id: int.tryParse((json['id'] ?? json['esim_id'] ?? 0).toString()) ?? 0,
      iccid: firstText([
        json['iccid'],
        json['sim_num'],
        json['simNum'],
        json['sim_iccid'],
        json['esim_iccid'],
      ]),
      provider: firstText([
        json['display_provider'],
        json['provider_name'],
        json['provider'],
        json['operator'],
        details['provider'],
      ], 'Roam2World'),
      packageName: firstText([
        json['package_name'],
        json['bundle_name'],
        json['plan_name'],
        plan['name'],
        package['name'],
        details['package_name'],
        details['name'],
      ], physical ? 'SIM package' : 'eSIM package'),
      customerName: firstText([
        json['customer_name'],
        json['delivery_recipient_name'],
        json['client_name'],
      ]),
      status: firstText([
        json['status'],
        json['activation_status'],
      ], 'pending'),
      installStatus: firstText([
        json['install_status'],
        json['profile_status'],
        json['activation_status'],
      ]),
      activationCode: firstText([
        json['activation_code'],
        json['lpa_code'],
        details['qrcodeContent'],
      ]),
      qrCode: firstText([
        json['recommended_qr_url'],
        json['qr_code_url'],
        json['qr_code'],
        json['qrCode'],
        json['qr_code_text'],
        details['qrcode'],
        details['qrcodeContent'],
      ]),
      expiresAt: parseDate(
        json['expires_at'] ??
            json['expiry_date'] ??
            json['expiration_date'] ??
            json['valid_until'] ??
            json['end_date'],
      ),
      lineType: physical ? 'physical_sim' : 'esim',
      dataLabel: firstText([
        json['data_label'],
        details['data_label'],
        normalizeData(json['data']),
        normalizeData(json['data_amount']),
        normalizeData(json['data_quantity']),
        normalizeData(plan['data']),
        normalizeData(package['data']),
        normalizeData(details['data']),
      ]),
      validityLabel: firstText([
        json['validity_label'],
        normalizeValidity(json['validity']),
        normalizeValidity(json['validity_days']),
        normalizeValidity(plan['validity']),
        normalizeValidity(package['validity']),
        normalizeValidity(details['validity']),
      ]),
      smdpAddress: firstText([
        json['smdp_address'],
        json['smdpAddress'],
        details['smdp_address'],
        details['smdpAddress'],
      ]),
      matchingId: firstText([
        json['matching_id'],
        json['matchingId'],
        details['matching_id'],
        details['matchingId'],
      ]),
      usageBytes: used,
      totalBytes: total,
    );
  }

  bool get isPhysicalSim => lineType == 'physical_sim';
  bool get isInstalled => installStatus.toLowerCase().contains('install');
  bool get hasQr => !isPhysicalSim && (qrCode.isNotEmpty || activationCode.isNotEmpty);
  bool get hasUsage => usageBytes != null && totalBytes != null && totalBytes! > 0;
  double? get usageRatio => hasUsage ? (usageBytes! / totalBytes!).clamp(0, 1) : null;
  bool get isActive {
    final value = status.toLowerCase();
    return value.contains('active') || value.contains('install');
  }
  bool get isPending {
    final value = status.toLowerCase();
    return value.contains('pending') ||
        value.contains('process') ||
        value.contains('provision') ||
        value.contains('issued') ||
        value.contains('ready');
  }
  bool get isExpired {
    final value = status.toLowerCase();
    if (value.contains('expired')) return true;
    return expiresAt != null && expiresAt!.isBefore(DateTime.now());
  }
}

double? _nullableDouble(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  return double.tryParse(value.toString());
}
