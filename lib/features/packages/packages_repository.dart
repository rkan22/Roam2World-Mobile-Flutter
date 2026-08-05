import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'package_catalog.dart';

class PackagesRepository {
  PackagesRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PackageCatalog> fetchPackages({
    String? search,
    String? destination,
    String? packageType,
    int limit = 100,
  }) {
    return _apiClient.get<PackageCatalog>(
      ApiEndpoints.mobilePackages,
      queryParameters: {
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (destination != null && destination.isNotEmpty) 'destination': destination,
        if (packageType != null && packageType.isNotEmpty) 'package_type': packageType,
      },
      parser: PackageCatalog.fromResponse,
    );
  }
}
