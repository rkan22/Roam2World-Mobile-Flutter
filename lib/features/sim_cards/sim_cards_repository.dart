import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'sim_card_models.dart';

class SimCardsRepository {
  SimCardsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<SimCardCatalog> fetchPackages({
    String? productId,
    String? region,
  }) {
    return _apiClient.get<SimCardCatalog>(
      ApiEndpoints.mobileSimPackages,
      queryParameters: {
        if (productId != null && productId.trim().isNotEmpty)
          'productId': productId.trim(),
        if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
      },
      parser: SimCardCatalog.fromResponse,
    );
  }

  Future<SimCardOrderResult> createOrder({
    required String productId,
    required int quantity,
    String? note,
  }) {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'must be at least 1');
    }
    return _apiClient.post<SimCardOrderResult>(
      ApiEndpoints.mobileSimOrders,
      data: {
        'package_id': productId.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      parser: SimCardOrderResult.fromResponse,
    );
  }

  Future<List<SimCardOrder>> fetchOrders() {
    return _apiClient.get<List<SimCardOrder>>(
      ApiEndpoints.mobileSimOrderHistory,
      parser: (response) {
        dynamic raw;

        if (response is List) {
          raw = response;
        } else if (response is Map) {
          final root = Map<String, dynamic>.from(response);
          raw = root['orders'] ??
              root['results'] ??
              root['data'] ??
              const [];
        } else {
          raw = const [];
        }

        return raw is List
            ? raw
                .whereType<Map>()
                .map((item) => SimCardOrder.fromJson(Map<String, dynamic>.from(item)))
                .toList(growable: false)
            : const [];
      },
    );
  }
}
