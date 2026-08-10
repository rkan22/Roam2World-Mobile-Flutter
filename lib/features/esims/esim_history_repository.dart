import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class EsimHistoryPage {
  const EsimHistoryPage({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });

  final List<EsimHistoryItem> items;
  final int totalCount;
  final bool hasMore;
}

class EsimHistoryItem {
  const EsimHistoryItem({
    required this.id,
    required this.iccid,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerPhone,
    required this.provider,
    required this.displayProvider,
    required this.planName,
    required this.status,
    required this.orderNumber,
    required this.packageId,
    this.dataGb,
    this.remainingGb,
    this.validityDays,
    this.purchasedAt,
    this.expiresAt,
  });

  final int id;
  final String iccid;
  final String customerFirstName;
  final String customerLastName;
  final String customerPhone;
  final String provider;
  final String displayProvider;
  final String planName;
  final String status;
  final String orderNumber;
  final String packageId;
  final double? dataGb;
  final double? remainingGb;
  final int? validityDays;
  final DateTime? purchasedAt;
  final DateTime? expiresAt;

  String get customerName => [customerFirstName, customerLastName]
      .where((value) => value.trim().isNotEmpty)
      .join(' ');

  bool get supportsTgtGbCheck =>
      provider.toLowerCase() == 'tgt' && iccid.replaceAll(RegExp(r'\D'), '').startsWith('8997');

  factory EsimHistoryItem.fromJson(Map<String, dynamic> json) {
    double? number(Object? value) => value == null ? null : double.tryParse('$value');
    int? integer(Object? value) => value == null ? null : int.tryParse('$value');

    return EsimHistoryItem(
      id: int.tryParse('${json['id'] ?? json['esim_id'] ?? ''}') ?? 0,
      iccid: '${json['iccid'] ?? ''}',
      customerFirstName: '${json['customer_first_name'] ?? ''}',
      customerLastName: '${json['customer_last_name'] ?? ''}',
      customerPhone: '${json['customer_phone'] ?? ''}',
      provider: '${json['provider'] ?? ''}',
      displayProvider: '${json['display_provider'] ?? json['provider'] ?? ''}',
      planName: '${json['plan_name'] ?? ''}',
      status: '${json['status'] ?? ''}',
      orderNumber: '${json['order_number'] ?? ''}',
      packageId: '${json['package_id'] ?? ''}',
      dataGb: number(json['data_gb']),
      remainingGb: number(json['remaining_gb']),
      validityDays: integer(json['validity_days']),
      purchasedAt: DateTime.tryParse('${json['purchased_at'] ?? ''}'),
      expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}'),
    );
  }
}

class TgtUsageSnapshot {
  const TgtUsageSnapshot({
    required this.supported,
    required this.iccid,
    required this.status,
    required this.profileStatus,
    required this.orderNo,
    required this.channelOrderNo,
    this.totalMb,
    this.usedMb,
    this.remainingMb,
  });

  final bool supported;
  final String iccid;
  final String status;
  final String profileStatus;
  final String orderNo;
  final String channelOrderNo;
  final double? totalMb;
  final double? usedMb;
  final double? remainingMb;

  double? get remainingGb => remainingMb == null ? null : remainingMb! / 1024;

  factory TgtUsageSnapshot.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final usage = root['usage'] is Map
        ? Map<String, dynamic>.from(root['usage'] as Map)
        : <String, dynamic>{};
    double? number(Object? value) => value == null ? null : double.tryParse('$value');
    return TgtUsageSnapshot(
      supported: root['supported'] == true,
      iccid: '${root['iccid'] ?? ''}',
      status: '${usage['status'] ?? ''}',
      profileStatus: '${usage['profile_status'] ?? ''}',
      orderNo: '${usage['order_no'] ?? ''}',
      channelOrderNo: '${usage['channel_order_no'] ?? ''}',
      totalMb: number(usage['total_mb']),
      usedMb: number(usage['used_mb']),
      remainingMb: number(usage['remaining_mb']),
    );
  }
}

class EsimHistoryRepository {
  EsimHistoryRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<EsimHistoryPage> fetchHistory({
    String? search,
    String? status,
    int limit = 100,
    int offset = 0,
  }) {
    return _apiClient.get<EsimHistoryPage>(
      ApiEndpoints.mobileEsimHistory,
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final raw = root['data'] is List ? root['data'] as List : const [];
        return EsimHistoryPage(
          items: raw
              .whereType<Map>()
              .map((item) => EsimHistoryItem.fromJson(Map<String, dynamic>.from(item)))
              .toList(),
          totalCount: int.tryParse('${root['total_count'] ?? root['count'] ?? raw.length}') ?? raw.length,
          hasMore: root['has_more'] == true,
        );
      },
    );
  }

  Future<TgtUsageSnapshot> checkTgtGb(String iccid) {
    return _apiClient.post<TgtUsageSnapshot>(
      ApiEndpoints.mobileTgtCheckGb,
      data: {'iccid': iccid},
      parser: TgtUsageSnapshot.fromResponse,
    );
  }
}
