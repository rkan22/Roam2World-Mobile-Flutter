import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'sim_converter_data.dart';

class SimConverterRepository {
  SimConverterRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<SimConverterWorkspace> fetchConversions() {
    return _apiClient.get<SimConverterWorkspace>(
      ApiEndpoints.simConverterConversions,
      queryParameters: const {'page_size': 100},
      parser: SimConverterWorkspace.fromResponse,
    );
  }

  Future<SimConverterStatistics> fetchStatistics() {
    return _apiClient.get<SimConverterStatistics>(
      ApiEndpoints.simConverterStatistics,
      parser: SimConverterStatistics.fromResponse,
    );
  }

  Future<ActivationParseResult> parseActivationCode(String activationCode) {
    return _apiClient.post<ActivationParseResult>(
      ApiEndpoints.simConverterParseActivationCode,
      data: {'activation_code': activationCode.trim()},
      parser: ActivationParseResult.fromResponse,
    );
  }
}
