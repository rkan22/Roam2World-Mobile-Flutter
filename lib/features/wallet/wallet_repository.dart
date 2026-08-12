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
        // The wallet summary still contains the five most recent transactions,
        // so it remains useful if the dedicated history endpoint is unavailable.
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

  /// Canonical B2B wallet contract. Kept separate from [fetchWallet] so the
  /// existing finance UI can continue using its role-specific legacy summary
  /// until its response contract is migrated explicitly.
  Future<WalletData> fetchSmartWalletStatus() {
    return _apiClient.get<WalletData>(
      ApiEndpoints.mobileSmartWalletStatus,
      parser: WalletData.fromResponse,
    );
  }

  Future<dynamic> chargeOrder({
    required Object orderId,
    required double amount,
    String? currency,
    String? clientOrderId,
  }) {
    return _apiClient.post<dynamic>(
      ApiEndpoints.mobileSmartWalletChargeOrder,
      data: {
        'order_id': orderId,
        'amount': amount.toStringAsFixed(2),
        if (currency != null && currency.trim().isNotEmpty)
          'currency': currency.trim().toUpperCase(),
        if (clientOrderId != null && clientOrderId.trim().isNotEmpty)
          'client_order_id': clientOrderId.trim(),
      },
      parser: (response) => response,
    );
  }

  Future<dynamic> refundOrder({
    required Object orderId,
    double? amount,
    String? reason,
  }) {
    return _apiClient.post<dynamic>(
      ApiEndpoints.mobileSmartWalletRefundOrder,
      data: {
        'order_id': orderId,
        if (amount != null) 'amount': amount.toStringAsFixed(2),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      parser: (response) => response,
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
      (false, true) => ApiEndpoints.mobileResellerWalletRequestApprove(request.id),
      (false, false) => ApiEndpoints.mobileResellerWalletRequestReject(request.id),
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
