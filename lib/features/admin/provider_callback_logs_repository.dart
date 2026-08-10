import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class ProviderCallbackLogItem {
  const ProviderCallbackLogItem({
    required this.id,
    required this.provider,
    required this.eventType,
    required this.providerOrderId,
    required this.iccid,
    required this.status,
    required this.signatureValid,
    required this.errorMessage,
    required this.createdAt,
  });

  final int id;
  final String provider;
  final String eventType;
  final String providerOrderId;
  final String iccid;
  final String status;
  final bool? signatureValid;
  final String errorMessage;
  final DateTime? createdAt;

  factory ProviderCallbackLogItem.fromJson(Map<String, dynamic> json) {
    return ProviderCallbackLogItem(
      id: int.tryParse('${json['id'] ?? ''}') ?? 0,
      provider: '${json['provider'] ?? ''}',
      eventType: '${json['event_type'] ?? ''}',
      providerOrderId: '${json['provider_order_id'] ?? ''}',
      iccid: '${json['iccid'] ?? ''}',
      status: '${json['status'] ?? ''}',
      signatureValid: json['signature_valid'] is bool ? json['signature_valid'] as bool : null,
      errorMessage: '${json['error_message'] ?? ''}',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }
}

class ProviderCallbackLogsRepository {
  ProviderCallbackLogsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ProviderCallbackLogItem>> fetchLogs({String? provider, String? status}) {
    return _apiClient.get<List<ProviderCallbackLogItem>>(
      ApiEndpoints.mobileAdminProviderCallbackLogs,
      queryParameters: {
        'limit': 200,
        if (provider != null && provider.trim().isNotEmpty) 'provider': provider.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final raw = root['data'] is List ? root['data'] as List : const [];
        return raw
            .whereType<Map>()
            .map((item) => ProviderCallbackLogItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  Future<ProviderCallbackLogItem> updateStatus(int id, String status) {
    return _apiClient.patch<ProviderCallbackLogItem>(
      ApiEndpoints.mobileAdminProviderCallbackLogDetail(id),
      data: {'status': status},
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final data = root['data'] is Map ? Map<String, dynamic>.from(root['data'] as Map) : root;
        return ProviderCallbackLogItem.fromJson(data);
      },
    );
  }
}
