import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class ManualFulfillmentWorkspaceData {
  const ManualFulfillmentWorkspaceData({
    required this.products,
    required this.inventory,
    required this.tasks,
    required this.availableBlankStock,
  });

  final List<ManualProductItem> products;
  final List<ManualInventoryItem> inventory;
  final List<ManualTaskItem> tasks;
  final int availableBlankStock;
}

class ManualProductItem {
  const ManualProductItem({
    required this.packageId,
    required this.name,
    required this.operatorName,
    required this.type,
    required this.currency,
    required this.providerCost,
    required this.active,
    required this.availableStock,
  });

  final String packageId;
  final String name;
  final String operatorName;
  final String type;
  final String currency;
  final double providerCost;
  final bool active;
  final int? availableStock;

  factory ManualProductItem.fromJson(Map<String, dynamic> json) =>
      ManualProductItem(
        packageId: '${json['package_id'] ?? ''}',
        name: '${json['product_name'] ?? ''}',
        operatorName: '${json['operator_name'] ?? ''}',
        type: '${json['product_type'] ?? ''}',
        currency: '${json['currency'] ?? 'USD'}',
        providerCost: double.tryParse('${json['provider_cost'] ?? json['base_price'] ?? 0}') ?? 0,
        active: json['is_active'] == true,
        availableStock: json['available_stock'] == null
            ? null
            : int.tryParse('${json['available_stock']}'),
      );
}

class ManualInventoryItem {
  const ManualInventoryItem({
    required this.id,
    required this.iccid,
    required this.status,
    required this.orderNumber,
  });

  final int id;
  final String iccid;
  final String status;
  final String orderNumber;

  factory ManualInventoryItem.fromJson(Map<String, dynamic> json) =>
      ManualInventoryItem(
        id: int.tryParse('${json['id'] ?? 0}') ?? 0,
        iccid: '${json['iccid'] ?? ''}',
        status: '${json['status'] ?? ''}',
        orderNumber: '${json['assigned_order_number'] ?? ''}',
      );
}

class ManualTaskItem {
  const ManualTaskItem({
    required this.taskId,
    required this.status,
    required this.productName,
    required this.productType,
    required this.orderNumber,
    required this.customerName,
    required this.customerEmail,
    required this.iccid,
    required this.fulfillmentPartner,
    required this.canSendToFlexnet,
    required this.supplierReference,
    required this.errorMessage,
  });

  final String taskId;
  final String status;
  final String productName;
  final String productType;
  final String orderNumber;
  final String customerName;
  final String customerEmail;
  final String iccid;
  final String fulfillmentPartner;
  final bool canSendToFlexnet;
  final String supplierReference;
  final String errorMessage;

  bool get isFinished => const {'completed', 'qr_ready', 'cancelled'}.contains(status);

  factory ManualTaskItem.fromJson(Map<String, dynamic> json) => ManualTaskItem(
        taskId: '${json['task_id'] ?? ''}',
        status: '${json['status'] ?? ''}',
        productName: '${json['product_name'] ?? ''}',
        productType: '${json['product_type'] ?? ''}',
        orderNumber: '${json['order_number'] ?? ''}',
        customerName: '${json['customer_name'] ?? ''}',
        customerEmail: '${json['customer_email'] ?? ''}',
        iccid: '${json['iccid'] ?? ''}',
        fulfillmentPartner: '${json['fulfillment_partner'] ?? ''}',
        canSendToFlexnet: json['can_send_to_flexnet'] == true,
        supplierReference: '${json['supplier_reference'] ?? ''}',
        errorMessage: '${json['error_message'] ?? ''}',
      );
}

class ManualFulfillmentRepository {
  ManualFulfillmentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ManualFulfillmentWorkspaceData> fetchWorkspace() async {
    final results = await Future.wait([
      _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.manualAdminProducts,
        parser: (response) => Map<String, dynamic>.from(response as Map),
      ),
      _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.manualAdminSimInventory,
        parser: (response) => Map<String, dynamic>.from(response as Map),
      ),
      _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.manualAdminTasks,
        parser: (response) => Map<String, dynamic>.from(response as Map),
      ),
    ]);
    final productsRoot = results[0];
    final inventoryRoot = results[1];
    final tasksRoot = results[2];
    return ManualFulfillmentWorkspaceData(
      products: _list(productsRoot['data'])
          .map(ManualProductItem.fromJson)
          .toList(),
      inventory: _list(inventoryRoot['data'])
          .map(ManualInventoryItem.fromJson)
          .toList(),
      tasks: _list(tasksRoot['data']).map(ManualTaskItem.fromJson).toList(),
      availableBlankStock:
          int.tryParse('${inventoryRoot['available_blank_stock'] ?? 0}') ?? 0,
    );
  }

  Future<void> addBlankSims(List<String> iccids) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.manualAdminSimInventory,
      data: {'iccids': iccids},
      parser: (response) => Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> sendToFlexnet(String taskId) => _taskAction(
        ApiEndpoints.manualAdminSendToFlexnet(taskId),
        const {},
      );

  Future<void> assignQr(
    String taskId, {
    required String code,
    String supplierReference = '',
  }) =>
      _taskAction(ApiEndpoints.manualAdminAssignQr(taskId), {
        'qr_code': code,
        if (supplierReference.trim().isNotEmpty)
          'supplier_reference': supplierReference.trim(),
      });

  Future<void> activateSim(
    String taskId, {
    String activationReference = '',
  }) =>
      _taskAction(ApiEndpoints.manualAdminActivateSim(taskId), {
        if (activationReference.trim().isNotEmpty)
          'activation_reference': activationReference.trim(),
      });

  Future<void> cancelTask(String taskId, {String reason = ''}) =>
      _taskAction(ApiEndpoints.manualAdminCancelTask(taskId), {
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      });

  Future<void> _taskAction(String path, Map<String, dynamic> data) async {
    await _apiClient.post<Map<String, dynamic>>(
      path,
      data: data,
      parser: (response) => Map<String, dynamic>.from(response as Map),
    );
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
