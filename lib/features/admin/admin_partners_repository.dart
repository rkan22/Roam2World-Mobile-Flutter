import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'admin_partners_data.dart';

class AdminPartnersRepository {
  AdminPartnersRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AdminPartnerList> fetchResellers() {
    return _apiClient.get<AdminPartnerList>(
      '/api/v1/resellers/resellers/',
      parser: AdminPartnerList.fromResponse,
    );
  }

  Future<AdminPartnerList> fetchDealers() {
    return _apiClient.get<AdminPartnerList>(
      ApiEndpoints.mobileAdminDealers,
      parser: AdminPartnerList.fromResponse,
    );
  }
}
