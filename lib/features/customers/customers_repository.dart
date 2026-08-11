import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/routing/app_role.dart';
import '../../core/storage/token_storage.dart';

class CustomerDirectory {
  const CustomerDirectory({required this.names, required this.count});

  final List<String> names;
  final int count;

  factory CustomerDirectory.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final raw = data['clients'] ?? data['results'] ?? data['items'] ?? const [];
    final names = raw is List
        ? raw
              .whereType<Map>()
              .map((item) {
                final json = Map<String, dynamic>.from(item);
                final first = '${json['first_name'] ?? ''}'.trim();
                final last = '${json['last_name'] ?? ''}'.trim();
                return '${json['full_name'] ?? json['name'] ?? json['company_name'] ?? '$first $last'}'
                    .trim();
              })
              .where((name) => name.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    return CustomerDirectory(
      names: names,
      count:
          int.tryParse('${data['count'] ?? data['total'] ?? names.length}') ??
          names.length,
    );
  }
}

class CustomersRepository {
  CustomersRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<CustomerDirectory> fetchCustomers() async {
    final profile = await _tokenStorage.readProfile();
    final role = parseAppRole(profile?['role']?.toString());
    return _apiClient.get<CustomerDirectory>(
      role == AppRole.dealer
          ? ApiEndpoints.dealerClients
          : ApiEndpoints.resellerClients,
      parser: CustomerDirectory.fromResponse,
    );
  }
}
