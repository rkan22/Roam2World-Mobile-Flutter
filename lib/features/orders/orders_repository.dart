import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/routing/app_role.dart';
import '../../core/storage/token_storage.dart';
import '../packages/package_catalog.dart';
import 'order_history.dart';
import 'order_result.dart';

class OrdersRepository {
  OrdersRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<OrderHistory> fetchOrders({String? status, String? search}) async {
    final profile = await _tokenStorage.readProfile();
    final role = parseAppRole(profile?['role']?.toString());
    final isAdmin = role == AppRole.admin;

    final query = <String, dynamic>{};
    if (!isAdmin) {
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
    }

    final history = await _apiClient.get<OrderHistory>(
      isAdmin ? ApiEndpoints.mobileAdminOrders : ApiEndpoints.mobileOrders,
      queryParameters: query,
      parser: OrderHistory.fromResponse,
    );

    if (!isAdmin) return history;

    final normalizedStatus = status?.trim().toLowerCase() ?? '';
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final filtered = history.orders
        .where((order) {
          final statusMatches =
              normalizedStatus.isEmpty ||
              order.status.toLowerCase() == normalizedStatus;
          final searchMatches =
              normalizedSearch.isEmpty ||
              order.orderNumber.toLowerCase().contains(normalizedSearch) ||
              order.packageName.toLowerCase().contains(normalizedSearch) ||
              order.customerName.toLowerCase().contains(normalizedSearch);
          return statusMatches && searchMatches;
        })
        .toList(growable: false);

    return OrderHistory(orders: filtered, count: filtered.length);
  }

  Future<MobileOrderResult> createOrder({
    required MobilePackage package,
    required String firstName,
    required String lastName,
    required String phone,
    String? imei,
    String? simNumber,
  }) {
    final isWorldmove = package.provider.toLowerCase() == 'worldmove';
    final isManual = package.provider.toLowerCase() == 'manual';
    return _apiClient.post<MobileOrderResult>(
      isWorldmove
          ? ApiEndpoints.mobileWorldmoveOrders
          : isManual
          ? ApiEndpoints.manualRequest
          : ApiEndpoints.mobileOrders,
      data: {
        'package_id': package.id,
        if (isWorldmove) 'wmproductId': package.id,
        if (isWorldmove) 'qty': 1,
        if (isWorldmove) 'qrcodeType': 2,
        if (package.provider.isNotEmpty) 'provider': package.provider,
        'customer_first_name': firstName.trim(),
        'customer_last_name': lastName.trim(),
        'customer_phone': phone.trim(),
        if (isManual)
          'customer_name': '${firstName.trim()} ${lastName.trim()}'.trim(),
        if (imei != null && imei.trim().isNotEmpty) 'imei': imei.trim(),
        if (simNumber != null && simNumber.trim().isNotEmpty)
          'simNum': simNumber.replaceAll(RegExp(r'\D'), ''),
      },
      parser: (response) {
        if (!isWorldmove && !isManual) {
          return MobileOrderResult.fromResponse(response);
        }
        final enriched = Map<String, dynamic>.from(response as Map);
        enriched.putIfAbsent('package_name', () => package.name);
        enriched.putIfAbsent('price', () => package.price);
        enriched.putIfAbsent('currency', () => package.currency);
        enriched.putIfAbsent('customer_first_name', () => firstName.trim());
        enriched.putIfAbsent('customer_last_name', () => lastName.trim());
        return MobileOrderResult.fromResponse(enriched);
      },
    );
  }
}
