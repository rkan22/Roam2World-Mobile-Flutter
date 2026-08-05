import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'wallet_data.dart';
import 'wallet_request.dart';

class WalletRepository {
  WalletRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<WalletData> fetchWallet() {
    return _apiClient.get<WalletData>(
      ApiEndpoints.mobileWallet,
      parser: WalletData.fromResponse,
    );
  }

  Future<WalletRequest> createTopUpRequest({
    required double amount,
    required String currency,
    String? note,
  }) {
    return _apiClient.post<WalletRequest>(
      ApiEndpoints.mobileWalletRequests,
      data: {
        'amount': amount.toStringAsFixed(2),
        'currency': currency.toUpperCase(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      parser: WalletRequest.fromResponse,
    );
  }
}
