import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/cache/timed_cache.dart';
import 'wallet_data.dart';
import 'wallet_request.dart';

class WalletRepository {
  WalletRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

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
      final data = await _apiClient.get<WalletData>(
        ApiEndpoints.mobileWallet,
        parser: WalletData.fromResponse,
      );
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
