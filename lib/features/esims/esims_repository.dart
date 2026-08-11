import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'esim_catalog.dart';

class EsimsRepository {
  EsimsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

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

  Future<List<MobileRenewalOption>> fetchRenewalOptions(MobileEsim esim) async {
    final provider = esim.providerKey.toLowerCase();
    final path = provider.contains('tgt') || provider.contains('balkan')
        ? ApiEndpoints.mobileTgtRenewalOptions(esim.id)
        : provider.contains('vodafone') || provider.contains('airhub')
        ? ApiEndpoints.mobileVodafoneRenewalOptions(esim.id)
        : null;
    if (path == null) return const [];

    return _apiClient.get<List<MobileRenewalOption>>(
      path,
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final data = root['data'] is Map
            ? Map<String, dynamic>.from(root['data'] as Map)
            : root;
        final rows = data['renewal_options'];
        if (rows is! List) return const [];
        return rows
            .whereType<Map>()
            .map(
              (item) =>
                  MobileRenewalOption.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      },
    );
  }

  Future<String> renewTgtEsim(
    int id, {
    String? productCode,
    int? dataGb,
    double? finalPrice,
  }) {
    return _apiClient.post<String>(
      ApiEndpoints.mobileTgtRenew,
      data: {
        'esim_id': id,
        'source': 'mobile',
        if (productCode != null) 'product_code': productCode,
        if (dataGb != null) 'renewal_data_gb': dataGb,
        if (finalPrice != null) 'final_price': finalPrice,
      },
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        return '${root['message'] ?? root['data']?['message'] ?? 'Renewal submitted.'}';
      },
    );
  }

  Future<String> renewVodafoneEsim(int id, int dataGb, {double? finalPrice}) {
    return _apiClient.post<String>(
      ApiEndpoints.mobileVodafoneRenew,
      data: {
        'esim_id': id,
        'renewal_data_gb': dataGb,
        'source': 'mobile',
        if (finalPrice != null) 'final_price': finalPrice,
      },
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        return '${root['message'] ?? 'Vodafone renewal submitted.'}';
      },
    );
  }
}
