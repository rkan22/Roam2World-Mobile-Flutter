import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'wallet_data.dart';

class WalletRepository {
  WalletRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<WalletData> fetchWallet() {
    return _apiClient.get<WalletData>(
      ApiEndpoints.mobileWallet,
      parser: WalletData.fromResponse,
    );
  }
}
