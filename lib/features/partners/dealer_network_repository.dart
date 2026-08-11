import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'dealer_network_data.dart';

class DealerNetworkRepository {
  DealerNetworkRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<DealerNetworkData> fetchNetwork() async {
    final dealersFuture = _apiClient.get<List<DealerSummary>>(
      ApiEndpoints.resellerDealers,
      parser: (response) {
        final root = response is Map
            ? Map<String, dynamic>.from(response)
            : <String, dynamic>{};
        final data = root['data'] ?? root;
        final rows = data is List
            ? data
            : data is Map
            ? (data['results'] ?? data['data'] ?? const [])
            : const [];
        return rows is List
            ? rows
                  .whereType<Map>()
                  .map(
                    (item) =>
                        DealerSummary.fromJson(Map<String, dynamic>.from(item)),
                  )
                  .toList()
            : const <DealerSummary>[];
      },
    );

    final requestsFuture = _apiClient.get<List<DealerFundingRequest>>(
      ApiEndpoints.resellerPendingDealerRequests,
      parser: (response) {
        final root = response is Map
            ? Map<String, dynamic>.from(response)
            : <String, dynamic>{};
        final data = root['data'] ?? root;
        final rows = data is List
            ? data
            : data is Map
            ? (data['results'] ?? data['data'] ?? const [])
            : const [];
        return rows is List
            ? rows
                  .whereType<Map>()
                  .map(
                    (item) => DealerFundingRequest.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .where((item) => item.status == 'pending')
                  .toList()
            : const <DealerFundingRequest>[];
      },
    );

    final results = await Future.wait([dealersFuture, requestsFuture]);
    return DealerNetworkData(
      dealers: results[0] as List<DealerSummary>,
      pendingRequests: results[1] as List<DealerFundingRequest>,
    );
  }

  Future<List<DealerWalletTransfer>> fetchWalletHistory() {
    return _apiClient.get<List<DealerWalletTransfer>>(
      ApiEndpoints.resellerDealerWalletHistory,
      parser: (response) {
        final root = response is Map
            ? Map<String, dynamic>.from(response)
            : <String, dynamic>{};
        final data = root['data'] ?? root;
        final rows = data is List
            ? data
            : data is Map
            ? (data['results'] ??
                  data['transactions'] ??
                  data['wallet_transfers'] ??
                  const [])
            : const [];
        return rows is List
            ? rows
                  .whereType<Map>()
                  .map(
                    (item) => DealerWalletTransfer.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList()
            : const <DealerWalletTransfer>[];
      },
    );
  }

  Future<void> approveRequest(
    DealerFundingRequest request, {
    String? note,
  }) async {
    await _apiClient.post<dynamic>(
      ApiEndpoints.mobileDealerWalletRequestApprove(request.id),
      data: {
        if (note != null && note.trim().isNotEmpty) 'notes': note.trim(),
        if (note != null && note.trim().isNotEmpty)
          'reseller_notes': note.trim(),
      },
      parser: (data) => data,
    );
  }

  Future<void> transfer({
    required int dealerId,
    required double amount,
    required bool credit,
    String? note,
  }) async {
    final path = credit
        ? ApiEndpoints.mobileDealerAllocateBalance(dealerId)
        : ApiEndpoints.mobileDealerModifyBalance(dealerId);
    await _apiClient.post<dynamic>(
      path,
      data: {
        'amount': amount.toStringAsFixed(2),
        'direction': credit ? 'add_to_dealer' : 'refund_to_reseller',
        if (note != null && note.trim().isNotEmpty) 'reason': note.trim(),
      },
      parser: (data) => data,
    );
  }

  Future<void> setDealerSuspended(
    int dealerId, {
    required bool suspended,
    String? reason,
  }) async {
    await _apiClient.post<dynamic>(
      suspended
          ? ApiEndpoints.mobileDealerSuspend(dealerId)
          : ApiEndpoints.mobileDealerActivate(dealerId),
      data: {
        if (suspended && reason?.trim().isNotEmpty == true)
          'reason': reason!.trim(),
      },
      parser: (data) => data,
    );
  }
}
