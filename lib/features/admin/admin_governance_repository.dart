import '../../core/api/api_client.dart';

class AdminGovernanceRepository {
  AdminGovernanceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const rolePermissionsPath = '/api/v1/admin/role-permissions/';
  static const accountGovernancePath = '/api/v1/admin/account-governance/';
  static const catalogGovernancePath = '/api/v1/admin/catalog-governance/';

  Future<AdminGovernanceData> fetchAll() async {
    final results = await Future.wait([
      _get(rolePermissionsPath),
      _get(accountGovernancePath),
      _get(catalogGovernancePath),
    ]);
    return AdminGovernanceData(
      rolePermissions: results[0],
      accountGovernance: results[1],
      catalogGovernance: results[2],
    );
  }

  Future<Map<String, dynamic>> saveRolePermissions(Map<String, dynamic> value) =>
      _save(rolePermissionsPath, value);

  Future<Map<String, dynamic>> saveAccountGovernance(Map<String, dynamic> value) =>
      _save(accountGovernancePath, value);

  Future<Map<String, dynamic>> saveCatalogGovernance(Map<String, dynamic> value) =>
      _save(catalogGovernancePath, value);

  Future<Map<String, dynamic>> _get(String path) {
    return _apiClient.get<Map<String, dynamic>>(
      path,
      parser: _parseData,
    );
  }

  Future<Map<String, dynamic>> _save(
    String path,
    Map<String, dynamic> value,
  ) {
    return _apiClient.post<Map<String, dynamic>>(
      path,
      data: value,
      parser: _parseData,
    );
  }

  Map<String, dynamic> _parseData(dynamic response) {
    final root = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final data = root['data'];
    return data is Map ? Map<String, dynamic>.from(data) : root;
  }
}

class AdminGovernanceData {
  const AdminGovernanceData({
    required this.rolePermissions,
    required this.accountGovernance,
    required this.catalogGovernance,
  });

  final Map<String, dynamic> rolePermissions;
  final Map<String, dynamic> accountGovernance;
  final Map<String, dynamic> catalogGovernance;
}
