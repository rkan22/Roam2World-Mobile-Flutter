import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../packages/package_catalog.dart';
import 'order_history.dart';
import 'order_result.dart';

class OrdersRepository {
  OrdersRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<OrderHistory> fetchOrders({String? status, String? search}) {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    return _apiClient.get<OrderHistory>(
      ApiEndpoints.mobileOrders,
      queryParameters: query,
      parser: OrderHistory.fromResponse,
    );
  }

  Future<MobileOrderResult> createOrder({
    required MobilePackage package,
    required String firstName,
    required String lastName,
    required String phone,
    String? imei,
  }) {
    return _apiClient.post<MobileOrderResult>(
      ApiEndpoints.mobileOrders,
      data: {
        'package_id': package.id,
        if (package.provider.isNotEmpty) 'provider': package.provider,
        'customer_first_name': firstName.trim(),
        'customer_last_name': lastName.trim(),
        'customer_phone': phone.trim(),
        if (imei != null && imei.trim().isNotEmpty) 'imei': imei.trim(),
      },
      parser: MobileOrderResult.fromResponse,
    );
  }
}
