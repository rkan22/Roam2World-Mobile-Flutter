import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'admin_partners_data.dart';

class AdminPartnersRepository {
  AdminPartnersRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  Future<AdminPartnerList> fetchResellers() => _apiClient.get<AdminPartnerList>('/api/v1/resellers/resellers/', parser: AdminPartnerList.fromResponse);
  Future<AdminPartnerList> fetchDealers() => _apiClient.get<AdminPartnerList>(ApiEndpoints.mobileAdminDealers, parser: AdminPartnerList.fromResponse);

  Future<AdminResellerDetail> fetchResellerDetail(int id) => _apiClient.get<AdminResellerDetail>('/api/v1/resellers/resellers/$id/', parser: AdminResellerDetail.fromResponse);

  Future<AdminResellerDetail> updateReseller(int id, Map<String, dynamic> payload) => _apiClient.patch<AdminResellerDetail>('/api/v1/resellers/resellers/$id/', data: payload, parser: AdminResellerDetail.fromResponse);
}
