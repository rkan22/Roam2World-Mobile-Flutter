import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class ProviderOperationsRepository {
  ProviderOperationsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> checkUsage({
    required String provider,
    required String lookup,
  }) {
    final value = lookup.trim();
    switch (provider) {
      case 'tgt':
        return _apiClient.post<Map<String, dynamic>>(
          ApiEndpoints.mobileTgtCheckGb,
          data: value.toUpperCase().startsWith('89') ? {'iccid': value} : {'order_no': value},
          parser: _map,
        );
      case 'airhub':
        return _apiClient.post<Map<String, dynamic>>(
          ApiEndpoints.mobileAirhubUsageCheck,
          data: value.toUpperCase().startsWith('89') ? {'iccid': value} : {'order_id': value},
          parser: _map,
        );
      case 'worldmove':
        return _apiClient.post<Map<String, dynamic>>(
          ApiEndpoints.mobileWorldmoveUsage,
          data: {'simNum': value},
          parser: _map,
        );
      default:
        throw ArgumentError('Unsupported provider: $provider');
    }
  }

  Future<List<Map<String, dynamic>>> renewalOptions({
    required String provider,
    required int esimId,
  }) async {
    final path = provider == 'tgt'
        ? ApiEndpoints.mobileTgtRenewalOptions(esimId)
        : ApiEndpoints.mobileVodafoneRenewalOptions(esimId);
    final response = await _apiClient.get<Map<String, dynamic>>(path, parser: _map);
    final data = response['data'] is Map ? Map<String, dynamic>.from(response['data']) : response;
    final raw = data['renewal_options'] ?? data['options'] ?? const [];
    return raw is List
        ? raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList(growable: false)
        : const [];
  }

  Future<Map<String, dynamic>> renewTgt({
    required int esimId,
    required num dataGb,
  }) => _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.mobileTgtRenew,
        data: {
          'esim_id': esimId,
          'renewal_data_gb': dataGb,
          'source': 'flutter',
        },
        parser: _map,
      );

  Future<Map<String, dynamic>> renewVodafone({
    required int esimId,
    required num dataGb,
  }) => _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.mobileVodafoneRenew,
        data: {
          'esim_id': esimId,
          'renewal_data_gb': dataGb,
          'source': 'flutter',
        },
        parser: _map,
      );

  Future<Map<String, dynamic>> topupWorldmove({
    required String simNumber,
    required String productId,
  }) => _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.mobileWorldmoveTopup,
        data: {
          'simNum': simNumber.trim(),
          'wmproductId': productId.trim(),
          'source': 'flutter',
        },
        parser: _map,
      );

  static Map<String, dynamic> _map(dynamic response) =>
      response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
}
