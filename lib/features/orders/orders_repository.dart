import 'dart:math';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/routing/app_role.dart';
import '../../core/storage/token_storage.dart';
import '../esims/esim_history_repository.dart';
import '../packages/package_catalog.dart';
import 'order_history.dart';
import 'order_result.dart';

class OrdersRepository {
  OrdersRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final Map<String, String> _checkoutClientOrderIds = <String, String>{};

  Future<OrderHistory> fetchOrders({String? status, String? search}) async {
    final profile = await _tokenStorage.readProfile();
    final role = parseAppRole(profile?['role']?.toString());
    final isAdmin = role == AppRole.admin;

    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final history = await _apiClient.get<OrderHistory>(
      isAdmin ? ApiEndpoints.mobileAdminOrders : ApiEndpoints.mobileOrders,
      queryParameters: query,
      parser: OrderHistory.fromResponse,
    );

    final enrichedHistory = await _enrichCustomerNames(history);
    if (!isAdmin) return enrichedHistory;

    final normalizedStatus = status?.trim().toLowerCase() ?? '';
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final filtered = enrichedHistory.orders
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

  Future<OrderHistory> _enrichCustomerNames(OrderHistory history) async {
    if (history.orders.every((order) => order.customerName.trim().isNotEmpty)) {
      return history;
    }

    try {
      final page = await _apiClient.get<EsimHistoryPage>(
        ApiEndpoints.mobileEsimHistory,
        queryParameters: const {'limit': 200, 'offset': 0},
        parser: (response) {
          final root = Map<String, dynamic>.from(response as Map);
          final raw = root['data'] is List ? root['data'] as List : const [];
          return EsimHistoryPage(
            items: raw
                .whereType<Map>()
                .map(
                  (item) =>
                      EsimHistoryItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(),
            totalCount:
                int.tryParse(
                  '${root['total_count'] ?? root['count'] ?? raw.length}',
                ) ??
                raw.length,
            hasMore: root['has_more'] == true,
          );
        },
      );

      final byEsimId = <int, String>{};
      final byOrderNumber = <String, String>{};
      for (final item in page.items) {
        final name = item.customerName.trim();
        if (name.isEmpty) continue;
        if (item.id > 0) byEsimId[item.id] = name;
        final orderNumber = item.orderNumber.trim().toLowerCase();
        if (orderNumber.isNotEmpty) byOrderNumber[orderNumber] = name;
      }

      final orders = history.orders
          .map((order) {
            if (order.customerName.trim().isNotEmpty) return order;
            final byId = order.esimId == null ? null : byEsimId[order.esimId!];
            final byNumber =
                byOrderNumber[order.orderNumber.trim().toLowerCase()];
            final name = (byId ?? byNumber ?? '').trim();
            return name.isEmpty ? order : order.withCustomerName(name);
          })
          .toList(growable: false);

      return OrderHistory(orders: orders, count: history.count);
    } catch (_) {
      return history;
    }
  }

  Future<MobileOrderResult> createOrder({
    required MobilePackage package,
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    String? imei,
    String? simNumber,
  }) async {
    final isAdmin = package.provider.toLowerCase() == 'manual';
    if (isAdmin) {
      return _createLegacyManualOrder(
        package: package,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        imei: imei,
        simNumber: simNumber,
      );
    }

    final normalizedSim = _normalizedSimIdentifier(package, simNumber ?? '');
    final key = _checkoutKey(
      package: package,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      imei: imei,
      simNumber: normalizedSim,
    );
    final clientOrderId = _checkoutClientOrderIds.putIfAbsent(
      key,
      _newClientOrderId,
    );

    try {
      final result = await _apiClient.post<MobileOrderResult>(
        '/api/v1/mobile/b2b/checkout/',
        data: {
          'category': package.packageType.isNotEmpty
              ? package.packageType
              : package.destinationKey,
          'package_id': package.id,
          'quantity': 1,
          'customer_first_name': firstName.trim(),
          'customer_last_name': lastName.trim(),
          'customer_phone': phone.trim(),
          if (email != null && email.trim().isNotEmpty)
            'customer_email': email.trim(),
          'client_order_id': clientOrderId,
          if (normalizedSim.isNotEmpty) 'sim_iccid': normalizedSim,
        },
        parser: (response) => MobileOrderResult.fromResponse(response),
      );
      _checkoutClientOrderIds.remove(key);
      return result;
    } catch (_) {
      rethrow;
    }
  }

  String _checkoutKey({
    required MobilePackage package,
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    String? imei,
    String? simNumber,
  }) {
    return [
      package.id,
      package.packageType,
      firstName.trim().toLowerCase(),
      lastName.trim().toLowerCase(),
      phone.trim(),
      email?.trim().toLowerCase() ?? '',
      imei?.trim() ?? '',
      simNumber ?? '',
    ].join('|');
  }

  Future<MobileOrderResult> _createLegacyManualOrder({
    required MobilePackage package,
    required String firstName,
    required String lastName,
    required String phone,
    String? imei,
    String? simNumber,
  }) {
    return _apiClient.post<MobileOrderResult>(
      ApiEndpoints.manualRequest,
      data: {
        'package_id': package.id,
        'customer_name': '${firstName.trim()} ${lastName.trim()}'.trim(),
        'customer_first_name': firstName.trim(),
        'customer_last_name': lastName.trim(),
        'customer_phone': phone.trim(),
        if (imei != null && imei.trim().isNotEmpty) 'imei': imei.trim(),
        if (simNumber != null && simNumber.trim().isNotEmpty)
          'simNum': simNumber.replaceAll(RegExp(r'\D'), ''),
      },
      parser: (response) {
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

  String _normalizedSimIdentifier(MobilePackage package, String raw) {
    if (raw.trim().isEmpty) return '';
    if (package.provider.toLowerCase() == 'tgt' &&
        package.packageType.toLowerCase() == 'simcard') {
      return raw
          .replaceAll(RegExp(r'[\s-]'), '')
          .toUpperCase()
          .replaceAll(RegExp(r'[^0-9A-Z]'), '');
    }
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  String _newClientOrderId() {
    final random = Random.secure();
    final suffix = List.generate(
      12,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return 'mobile-${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }
}
