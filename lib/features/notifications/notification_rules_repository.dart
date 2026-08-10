import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'notification_rules.dart';

class NotificationRulesRepository {
  NotificationRulesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<NotificationRule>> fetchRules() {
    return _apiClient.get<List<NotificationRule>>(
      ApiEndpoints.notificationRules,
      parser: (response) {
        final root = response is Map
            ? Map<String, dynamic>.from(response)
            : <String, dynamic>{};
        final data = root['data'] ?? root;
        final rows = data is List
            ? data
            : data is Map
                ? (data['results'] ?? data['rules'] ?? const [])
                : const [];
        return rows is List
            ? rows
                .whereType<Map>()
                .map(
                  (item) => NotificationRule.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
            : const <NotificationRule>[];
      },
    );
  }

  Future<void> saveRules(List<NotificationRule> rules) async {
    await _apiClient.post<dynamic>(
      ApiEndpoints.notificationRules,
      data: {'rules': rules.map((rule) => rule.toJson()).toList()},
      parser: (data) => data,
    );
  }
}
