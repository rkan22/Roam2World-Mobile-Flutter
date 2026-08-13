import '../../core/api/api_client.dart';

class SimAgentRemoteRepository {
  SimAgentRemoteRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchCredits() async {
    return _apiClient.get<Map<String, dynamic>>(
      '/api/v1/sim-agent/credits/',
      parser: _map,
    );
  }

  Future<List<Map<String, dynamic>>> fetchDevices() async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/api/v1/sim-agent/devices/',
      parser: _list,
    );
  }

  Future<List<Map<String, dynamic>>> fetchJobs() async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/api/v1/sim-agent/jobs/',
      parser: _list,
    );
  }

  Future<Map<String, dynamic>> queueJob({
    required Object deviceId,
    required Object esimId,
  }) {
    return _apiClient.post<Map<String, dynamic>>(
      '/api/v1/sim-agent/jobs/',
      data: {'device_id': deviceId, 'esim_id': esimId},
      parser: _map,
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    final root = value is Map && value['data'] is Map
        ? Map<String, dynamic>.from(value['data'] as Map)
        : value is Map
            ? Map<String, dynamic>.from(value)
            : const <String, dynamic>{};
    final raw = root['results'] ?? root['data'] ?? value;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
