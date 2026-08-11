import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class ProviderOperationResult {
  const ProviderOperationResult({
    required this.success,
    required this.provider,
    required this.message,
    required this.data,
  });

  final bool success;
  final String provider;
  final String message;
  final Map<String, dynamic> data;

  factory ProviderOperationResult.fromResponse(dynamic response) {
    final root = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final nested = root['data'];
    return ProviderOperationResult(
      success: root['success'] != false,
      provider: (root['provider'] ?? root['actual_provider'] ?? '').toString(),
      message: (root['message'] ?? root['error'] ?? '').toString(),
      data: nested is Map ? Map<String, dynamic>.from(nested) : root,
    );
  }
}

class TgtBulkItem {
  const TgtBulkItem({
    required this.packageId,
    required this.iccid,
    this.customerEmail,
    this.customerName,
    this.customerPhone,
  });

  final String packageId;
  final String iccid;
  final String? customerEmail;
  final String? customerName;
  final String? customerPhone;

  Map<String, dynamic> toJson() => {
    'package_id': packageId,
    'iccid': iccid,
    if (customerEmail?.trim().isNotEmpty == true)
      'customer_email': customerEmail!.trim(),
    if (customerName?.trim().isNotEmpty == true)
      'customer_name': customerName!.trim(),
    if (customerPhone?.trim().isNotEmpty == true)
      'customer_phone': customerPhone!.trim(),
  };
}

class ProviderLifecycleRepository {
  ProviderLifecycleRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ProviderOperationResult> topUpWorldmove({
    required String packageId,
    required String simNumber,
  }) => _post(ApiEndpoints.mobileWorldmoveTopup, {
    'wmproductId': packageId.trim(),
    'simNum': simNumber.trim(),
  });

  Future<ProviderOperationResult> checkAirhubUsage({
    String? orderId,
    String? iccid,
  }) => _post(ApiEndpoints.mobileAirhubUsageCheck, {
    if (orderId?.trim().isNotEmpty == true) 'order_id': orderId!.trim(),
    if (iccid?.trim().isNotEmpty == true) 'iccid': iccid!.trim(),
  });

  Future<ProviderOperationResult> checkEsimcardUsage(String esimId) =>
      _post(ApiEndpoints.mobileEsimcardUsageCheck, {'esim_id': esimId.trim()});

  Future<ProviderOperationResult> topUpEsimcard({
    required String esimId,
    required String packageId,
  }) => _post(ApiEndpoints.mobileEsimcardTopupCheckout, {
    'esim_id': esimId.trim(),
    'package_id': packageId.trim(),
  });

  Future<ProviderOperationResult> checkSmartUsage({
    required String provider,
    String? esimId,
    String? iccid,
    String? orderId,
  }) => _post(ApiEndpoints.mobileSmartUsageCheck, {
    'provider': provider.trim(),
    if (esimId?.trim().isNotEmpty == true) 'esim_id': esimId!.trim(),
    if (iccid?.trim().isNotEmpty == true) 'iccid': iccid!.trim(),
    if (orderId?.trim().isNotEmpty == true) 'order_id': orderId!.trim(),
  });

  Future<ProviderOperationResult> syncFlexnetEsim(int esimId) =>
      _post(ApiEndpoints.mobileFlexnetEsimSync(esimId), const {});

  Future<ProviderOperationResult> submitTgtBulkTopup(
    List<TgtBulkItem> items, {
    bool validateOnly = false,
    String? batchId,
  }) => _submitTgtBulk(
    ApiEndpoints.mobileTgtBulkTopup,
    items,
    validateOnly: validateOnly,
    batchId: batchId,
  );

  Future<ProviderOperationResult> checkWorldmoveUsage({
    required String iccid,
    String? orderId,
  }) => _post(ApiEndpoints.mobileWorldmoveUsage, {
    'iccid': iccid.trim(),
    if (orderId?.trim().isNotEmpty == true) 'orderId': orderId!.trim(),
  });

  Future<ProviderOperationResult> submitTgtBulkActivation(
    List<TgtBulkItem> items, {
    bool validateOnly = false,
    String? batchId,
  }) => _submitTgtBulk(
    ApiEndpoints.mobileTgtBulkActivate,
    items,
    validateOnly: validateOnly,
    batchId: batchId,
  );

  Future<ProviderOperationResult> _submitTgtBulk(
    String path,
    List<TgtBulkItem> items, {
    required bool validateOnly,
    String? batchId,
  }) => _post(path, {
    'validate_only': validateOnly,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    if (batchId?.trim().isNotEmpty == true) 'batch_id': batchId!.trim(),
  });

  Future<ProviderOperationResult> _post(
    String path,
    Map<String, dynamic> data,
  ) => _apiClient.post<ProviderOperationResult>(
    path,
    data: data,
    parser: ProviderOperationResult.fromResponse,
  );
}
