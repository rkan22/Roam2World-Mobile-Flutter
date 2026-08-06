import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'esim_catalog.dart';

class EsimsRepository {
  EsimsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<EsimCatalog> fetchEsims({String? search, String? status}) {
    return _apiClient.get<EsimCatalog>(
      ApiEndpoints.mobileEsims,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
      },
      parser: EsimCatalog.fromResponse,
    );
  }

  Future<MobileEsim> fetchEsimDetail(int id) {
    return _apiClient.get<MobileEsim>(
      ApiEndpoints.mobileEsimDetail(id),
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final data = root['data'] is Map
            ? Map<String, dynamic>.from(root['data'] as Map)
            : root;
        final item = data['esim'] is Map
            ? Map<String, dynamic>.from(data['esim'] as Map)
            : data;
        return MobileEsim.fromJson(item);
      },
    );
  }
}
