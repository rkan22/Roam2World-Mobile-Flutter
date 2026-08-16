import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/cache/timed_cache.dart';
import 'wallet_data.dart';
import 'wallet_request.dart';

class WalletRepository {
  WalletRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static final TimedCache<WalletData> _cache = TimedCache<WalletData>(
    ttl: const Duration(seconds: 45),
  );

  final ApiClient _apiClient;
  bool lastFetchUsedStale = false;

  Future<WalletData> fetchWallet({bool forceRefresh = false}) async {
    lastFetchUsedStale = false;
    if (!forceRefresh) {
      final cached = _cache.value;
      if (cached != null) return cached;
    }

    try {
      var data = await _apiClient.get<WalletData>(
        ApiEndpoints.mobileWallet,
        parser: WalletData.fromResponse,
      );
      try {
        final page = await fetchTransactions();
        data = data.copyWith(transactions: page.transactions);
      } catch (_) {
        // Keep the wallet summary usable if transaction history is temporarily unavailable.
      }
      _cache.set(data);
      return data;
    } catch (_) {
      final stale = _cache.staleValue;
      if (stale != null) {
        lastFetchUsedStale = true;
        return stale;
      }
      rethrow;
    }
  }

  /// B2B wallet status uses the live mobile wallet contract. Checkout itself
  /// performs the atomic debit on the backend; the mobile client must not
  /// perform a second charge.
  Future<WalletData> fetchSmartWalletStatus() {
    return _apiClient.get<WalletData>(
      ApiEndpoints.mobileWallet,
      parser: WalletData.fromResponse,
    );
  }

  Future<WalletTransactionPage> fetchTransactions({
    int limit = 50,
    String? transactionType,
  }) {
    return _apiClient.get<WalletTransactionPage>(
      ApiEndpoints.mobileTransactions,
      queryParameters: {
        'limit': limit.clamp(1, 200),
        if (transactionType != null && transactionType.isNotEmpty)
          'transaction_type': transactionType,
      },
      parser: WalletTransactionPage.fromResponse,
    );
  }

  Future<ProviderAllocationData> fetchProviderAllocations() {
    return _apiClient.get<ProviderAllocationData>(
      ApiEndpoints.providerAllocations,
      parser: ProviderAllocationData.fromResponse,
    );
  }

  Future<ProviderAllocationData> saveProviderAllocations(
    Map<String, double> allocations,
  ) {
    return _apiClient.put<ProviderAllocationData>(
      ApiEndpoints.providerAllocations,
      data: {
        'allocations': allocations.map(
          (key, value) => MapEntry(key, value.toStringAsFixed(2)),
        ),
      },
      parser: ProviderAllocationData.fromResponse,
    );
  }

  Future<List<WalletRequest>> fetchTopUpRequests() {
    return _apiClient.get<List<WalletRequest>>(
      ApiEndpoints.mobileWalletRequests,
      parser: WalletRequest.listFromResponse,
    );
  }

  Future<List<WalletRequest>> fetchReviewRequests({
    required String reviewerRole,
    String status = 'pending',
  }) {
    final path = reviewerRole.toLowerCase() == 'admin'
        ? ApiEndpoints.mobileResellerWalletRequests
        : ApiEndpoints.mobileDealerWalletRequests;
    return _apiClient.get<List<WalletRequest>>(
      path,
      queryParameters: {'status': status},
      parser: WalletRequest.listFromResponse,
    );
  }

  Future<WalletRequest> reviewRequest({
    required WalletRequest request,
    required bool approve,
    String? note,
  }) async {
    final isDealerRequest = request.requestType == 'dealer_balance_request';
    final path = switch ((isDealerRequest, approve)) {
      (true, true) => ApiEndpoints.mobileDealerWalletRequestApprove(request.id),
      (true, false) => ApiEndpoints.mobileDealerWalletRequestReject(request.id),
      (false, true) => ApiEndpoints.mobileResellerWalletRequestApprove(
        request.id,
      ),
      (false, false) => ApiEndpoints.mobileResellerWalletRequestReject(
        request.id,
      ),
    };
    final result = await _apiClient.post<WalletRequest>(
      path,
      data: {
        if (note != null && note.trim().isNotEmpty)
          approve ? 'notes' : 'reason': note.trim(),
      },
      parser: WalletRequest.fromResponse,
    );
    _cache.clear();
    return result;
  }

  Future<WalletRequest> adjustTopUpRequest({
    required int requestId,
    required double amount,
    required String reason,
  }) async {
    final result = await _apiClient.post<WalletRequest>(
      ApiEndpoints.adminWalletTopUpAdjust(requestId),
      data: {'amount': amount.toStringAsFixed(2), 'reason': reason.trim()},
      parser: WalletRequest.fromResponse,
    );
    _cache.clear();
    return result;
  }

  Future<WalletRequest> refundTopUpRequest({
    required int requestId,
    required double amount,
    required String reason,
  }) async {
    final result = await _apiClient.post<WalletRequest>(
      ApiEndpoints.adminWalletTopUpRefund(requestId),
      data: {'amount': amount.toStringAsFixed(2), 'reason': reason.trim()},
      parser: WalletRequest.fromResponse,
    );
    _cache.clear();
    return result;
  }

  Future<WalletRequest> createTopUpRequest({
    required double amount,
    required String currency,
    String? note,
  }) async {
    final request = await _apiClient.post<WalletRequest>(
      ApiEndpoints.mobileWalletRequests,
      data: {
        'amount': amount.toStringAsFixed(2),
        'currency': currency.toUpperCase(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      parser: WalletRequest.fromResponse,
    );
    _cache.clear();
    return request;
  }

  void invalidateCache() => _cache.clear();
}

class ProviderAllocationData {
  const ProviderAllocationData({
    required this.walletBalance,
    required this.allocations,
  });

  final double walletBalance;
  final Map<String, double> allocations;

  double get allocated =>
      allocations.values.fold<double>(0, (sum, value) => sum + value);

  double get available => (walletBalance - allocated).clamp(0, double.infinity);

  factory ProviderAllocationData.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final raw = data['allocations'] is Map
        ? Map<String, dynamic>.from(data['allocations'] as Map)
        : const <String, dynamic>{};
    return ProviderAllocationData(
      walletBalance: double.tryParse('${data['wallet_balance'] ?? 0}') ?? 0,
      allocations: raw.map(
        (key, value) => MapEntry(key, double.tryParse('$value') ?? 0),
      ),
    );
  }
}
