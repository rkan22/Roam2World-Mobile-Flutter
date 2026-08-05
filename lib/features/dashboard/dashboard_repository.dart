import '../../core/api/api_client.dart';
import '../../core/api/mobile_api_endpoints.dart';
import 'dashboard_data.dart';

class DashboardRepository {
  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<DashboardData> fetchDashboard() {
    return _apiClient.get<DashboardData>(
      MobileApiEndpoints.dashboard,
      parser: DashboardData.fromResponse,
    );
  }
}
