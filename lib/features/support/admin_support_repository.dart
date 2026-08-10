import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'admin_support_data.dart';

class AdminSupportRepository {
  AdminSupportRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AdminSupportData> fetchTickets() {
    return _apiClient.get<AdminSupportData>(
      ApiEndpoints.mobileAdminSupportTickets,
      parser: AdminSupportData.fromResponse,
    );
  }

  Future<Map<String, dynamic>> fetchSystemHealth() {
    return _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.mobileAdminSystemHealth,
      parser: (response) {
        if (response is! Map) return const <String, dynamic>{};
        final root = Map<String, dynamic>.from(response);
        final data = root['data'];
        return data is Map
            ? Map<String, dynamic>.from(data)
            : Map<String, dynamic>.from(root);
      },
    );
  }
}
