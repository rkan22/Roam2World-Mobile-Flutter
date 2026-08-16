import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/routing/app_role.dart';
import '../../core/storage/token_storage.dart';

class CustomerDirectory {
  const CustomerDirectory({required this.customers, required this.count});

  final List<CustomerDirectoryItem> customers;
  final int count;

  /// Backwards-compatible name list used by existing callers/tests.
  List<String> get names =>
      customers.map((customer) => customer.name).toList(growable: false);

  factory CustomerDirectory.fromResponse(dynamic response) {
    final root = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final raw = data['clients'] ?? data['results'] ?? data['items'] ?? const [];
    final customers = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (item) => CustomerDirectoryItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.name.isNotEmpty)
            .toList(growable: false)
        : const <CustomerDirectoryItem>[];
    return CustomerDirectory(
      customers: customers,
      count:
          int.tryParse('${data['count'] ?? data['total'] ?? customers.length}') ??
          customers.length,
    );
  }
}

class CustomerDirectoryItem {
  const CustomerDirectoryItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.status,
    required this.isActive,
    required this.currentPlan,
    required this.totalOrders,
    required this.totalSpent,
    required this.totalEsims,
    required this.activeEsims,
  });

  final int? id;
  final String name;
  final String email;
  final String phoneNumber;
  final String status;
  final bool? isActive;
  final String currentPlan;
  final int totalOrders;
  final double totalSpent;
  final int totalEsims;
  final int activeEsims;

  factory CustomerDirectoryItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : const <String, dynamic>{};
    final stats = json['statistics'] is Map
        ? Map<String, dynamic>.from(json['statistics'] as Map)
        : const <String, dynamic>{};
    final first = '${json['first_name'] ?? user['first_name'] ?? ''}'.trim();
    final last = '${json['last_name'] ?? user['last_name'] ?? ''}'.trim();
    final fullName = '${json['full_name'] ?? json['name'] ?? json['company_name'] ?? '$first $last'}'.trim();
    final rawActive = json['is_active'];

    return CustomerDirectoryItem(
      id: int.tryParse('${json['id'] ?? ''}'),
      name: fullName,
      email: '${json['email'] ?? user['email'] ?? ''}'.trim(),
      phoneNumber: '${json['phone_number'] ?? user['phone_number'] ?? ''}'.trim(),
      status: '${json['status'] ?? ''}'.trim().toLowerCase(),
      isActive: rawActive is bool
          ? rawActive
          : rawActive == null
              ? null
              : rawActive.toString().toLowerCase() == 'true',
      currentPlan: '${json['current_plan'] ?? ''}'.trim(),
      totalOrders: _toInt(stats['total_orders'] ?? json['total_orders']),
      totalSpent: _toDouble(stats['total_spent'] ?? json['total_spent']),
      totalEsims: _toInt(stats['total_esims'] ?? json['total_esims']),
      activeEsims: _toInt(stats['active_esims'] ?? json['active_esims']),
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

int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
double _toDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;
