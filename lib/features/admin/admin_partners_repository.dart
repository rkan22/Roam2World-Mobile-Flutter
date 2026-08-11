import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'admin_partners_data.dart';

class AdminPartnersRepository {
  AdminPartnersRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AdminPartnerList> fetchResellers() {
    return _apiClient.get<AdminPartnerList>(
      ApiEndpoints.mobileAdminResellers,
      parser: AdminPartnerList.fromResponse,
    );
  }

  Future<AdminPartnerList> fetchDealers() {
    return _apiClient.get<AdminPartnerList>(
      ApiEndpoints.mobileAdminDealers,
      parser: AdminPartnerList.fromResponse,
    );
  }

  Future<void> updateResellerMarkup({
    required int resellerId,
    required double markupPercentage,
  }) => _updateMarkup(
    ApiEndpoints.mobileAdminResellerMarkup(resellerId),
    markupPercentage,
  );

  Future<void> updateDealerMarkup({
    required int dealerId,
    required double markupPercentage,
  }) => _updateMarkup(
    ApiEndpoints.mobileAdminDealerMarkup(dealerId),
    markupPercentage,
  );

  Future<void> _updateMarkup(String path, double markupPercentage) async {
    if (markupPercentage < 0 || markupPercentage > 100) {
      throw ArgumentError.value(
        markupPercentage,
        'markupPercentage',
        'Must be between 0 and 100.',
      );
    }
    await _apiClient.patch<Object?>(
      path,
      data: {'markup_percentage': markupPercentage.toStringAsFixed(2)},
      parser: (response) => response,
    );
  }
}
