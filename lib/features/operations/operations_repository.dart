import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../orders/order_history.dart';
import '../orders/orders_repository.dart';
import '../wallet/wallet_data.dart';
import '../wallet/wallet_repository.dart';
import 'operations_data.dart';

class OperationsRepository {
  OperationsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<OperationsData> fetchOperations() async {
    final systemHealth =
        await _safe<SystemHealthData>(
          () => _apiClient.get<SystemHealthData>(
            ApiEndpoints.mobileAdminSystemHealth,
            parser: SystemHealthData.fromResponse,
          ),
        ) ??
        const SystemHealthData.empty();

    final failed = await _safeList<FailedOrderItem>(
      () => _apiClient.get<List<FailedOrderItem>>(
        ApiEndpoints.failedOrders,
        parser: (response) => _rows(
          response,
        ).map((item) => FailedOrderItem.fromJson(item)).toList(growable: false),
      ),
    );

    final providerLogs = await _safeList<OperationLogItem>(
      () => _apiClient.get<List<OperationLogItem>>(
        ApiEndpoints.providerOperationLogs,
        parser: (response) => _rows(response)
            .map((item) => OperationLogItem.fromJson(item, 'Provider API'))
            .toList(growable: false),
      ),
    );
    final webhookLogs = await _safeList<OperationLogItem>(
      () => _apiClient.get<List<OperationLogItem>>(
        ApiEndpoints.webhookLogs,
        parser: (response) => _rows(response)
            .map((item) => OperationLogItem.fromJson(item, 'Webhook'))
            .toList(growable: false),
      ),
    );

    final adminActivity = await _safe<AdminActivityData>(
      () => _apiClient.get<AdminActivityData>(
        ApiEndpoints.mobileAdminActivityLogs,
        parser: AdminActivityData.fromResponse,
      ),
    );
    final adminAudit = adminActivity?.events ?? const <AuditEventItem>[];

    final dedicatedAudit = adminAudit.isNotEmpty
        ? adminAudit
        : await _safeList<AuditEventItem>(
            () => _apiClient.get<List<AuditEventItem>>(
              ApiEndpoints.auditLogs,
              parser: (response) => _rows(response)
                  .map((item) => AuditEventItem.fromJson(item))
                  .toList(growable: false),
            ),
          );

    final auditEvents = dedicatedAudit.isNotEmpty
        ? dedicatedAudit
        : await _composeAuditFallback();

    final logs = [...providerLogs, ...webhookLogs]
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
    auditEvents.sort(
      (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
        a.createdAt ?? DateTime(1970),
      ),
    );

    return OperationsData(
      failedOrders: failed,
      logs: logs,
      auditEvents: auditEvents,
      activitySummary:
          adminActivity?.summary ?? const AdminActivitySummary.empty(),
      systemHealth: systemHealth,
    );
  }

  Future<List<AuditEventItem>> _composeAuditFallback() async {
    final orders = await _safe<OrderHistory>(
      () => OrdersRepository(apiClient: _apiClient).fetchOrders(),
    );
    final wallet = await _safe<WalletData>(
      () => WalletRepository(
        apiClient: _apiClient,
      ).fetchWallet(forceRefresh: true),
    );
    final dealerRows = await _safeList<Map<String, dynamic>>(
      () => _apiClient.get<List<Map<String, dynamic>>>(
        ApiEndpoints.resellerDealerRequests,
        parser: _rows,
      ),
    );

    final events = <AuditEventItem>[];
    if (orders != null) {
      events.addAll(
        orders.orders
            .take(80)
            .map(
              (order) => AuditEventItem(
                id: 'order-${order.id}',
                actor: order.customerName.isEmpty
                    ? 'System'
                    : order.customerName,
                action: 'order_${order.status.toLowerCase()}',
                target: order.orderNumber.isEmpty
                    ? order.packageName
                    : order.orderNumber,
                source: 'orders',
                description: order.packageName,
                createdAt: order.createdAt,
              ),
            ),
      );
    }
    if (wallet != null) {
      events.addAll(
        wallet.transactions
            .take(80)
            .map(
              (txn) => AuditEventItem(
                id: 'wallet-${txn.id}',
                actor: 'System',
                action: txn.type.trim().isEmpty ? 'wallet' : txn.type,
                target: txn.id.isEmpty ? 'Wallet' : 'Wallet #${txn.id}',
                source: 'finance',
                description: txn.description,
                createdAt: txn.createdAt,
              ),
            ),
      );
    }
    events.addAll(
      dealerRows
          .take(80)
          .map(
            (row) => AuditEventItem.fromJson({
              ...row,
              'action': row['action'] ?? 'dealer_${row['status'] ?? 'request'}',
              'target': row['dealer_name'] ?? row['dealer_email'] ?? row['id'],
            }, source: 'dealers'),
          ),
    );
    return events;
  }

  Future<List<T>> _safeList<T>(Future<List<T>> Function() loader) async {
    try {
      return await loader();
    } catch (_) {
      return <T>[];
    }
  }

  Future<T?> _safe<T>(Future<T> Function() loader) async {
    try {
      return await loader();
    } catch (_) {
      return null;
    }
  }
}

List<Map<String, dynamic>> _rows(dynamic response) {
  if (response is List) {
    return response
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  if (response is! Map) return const [];
  final root = Map<String, dynamic>.from(response);
  dynamic data = root['data'] ?? root;
  if (data is Map) {
    data =
        data['results'] ??
        data['items'] ??
        data['logs'] ??
        data['events'] ??
        data['orders'] ??
        data['transactions'] ??
        data;
  }
  if (data is List) {
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}
