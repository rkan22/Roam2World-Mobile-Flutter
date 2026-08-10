class SimConversionSummary {
  const SimConversionSummary({
    required this.id,
    required this.status,
    required this.iccid,
    required this.activationCode,
    required this.profileName,
    required this.createdAt,
  });

  final String id;
  final String status;
  final String iccid;
  final String activationCode;
  final String profileName;
  final DateTime? createdAt;

  factory SimConversionSummary.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : const <String, dynamic>{};
    return SimConversionSummary(
      id: (json['id'] ?? json['conversion_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      iccid: (json['iccid'] ?? profile['iccid'] ?? '').toString(),
      activationCode: (json['activation_code'] ?? json['qr_code'] ?? '').toString(),
      profileName: (json['profile_name'] ?? profile['name'] ?? profile['nickname'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['created'] ?? '').toString()),
    );
  }
}

class SimConverterWorkspace {
  const SimConverterWorkspace({required this.conversions, required this.total});

  final List<SimConversionSummary> conversions;
  final int total;

  factory SimConverterWorkspace.fromResponse(dynamic response) {
    final root = response is Map
        ? Map<String, dynamic>.from(response)
        : const <String, dynamic>{};
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final raw = data['results'] ?? data['conversions'] ?? root['results'] ?? const [];
    final conversions = raw is List
        ? raw
            .whereType<Map>()
            .map((item) => SimConversionSummary.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <SimConversionSummary>[];
    return SimConverterWorkspace(
      conversions: conversions,
      total: int.tryParse((data['count'] ?? root['count'] ?? conversions.length).toString()) ?? conversions.length,
    );
  }
}

class ActivationParseResult {
  const ActivationParseResult({
    required this.valid,
    required this.smdpAddress,
    required this.matchingId,
    required this.iccid,
    required this.message,
  });

  final bool valid;
  final String smdpAddress;
  final String matchingId;
  final String iccid;
  final String message;

  factory ActivationParseResult.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final success = data['valid'] == true || data['success'] == true || root['success'] == true;
    return ActivationParseResult(
      valid: success,
      smdpAddress: (data['smdp_address'] ?? data['smdp'] ?? data['smdp_plus'] ?? '').toString(),
      matchingId: (data['matching_id'] ?? data['matchingId'] ?? '').toString(),
      iccid: (data['iccid'] ?? '').toString(),
      message: (data['message'] ?? root['message'] ?? '').toString(),
    );
  }
}
