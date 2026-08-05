import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'notification_data.dart';

class NotificationsRepository {
  NotificationsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<MobileNotificationItem>> fetchNotifications() {
    return _apiClient.get<List<MobileNotificationItem>>(
      ApiEndpoints.mobileNotifications,
      parser: parseMobileNotifications,
    );
  }

  Future<void> markRead(int notificationId) async {
    await _apiClient.post<Object?>(
      ApiEndpoints.mobileNotificationRead(notificationId),
      parser: (data) => data,
    );
  }

  Future<void> markUnread(int notificationId) async {
    await _apiClient.post<Object?>(
      ApiEndpoints.mobileNotificationUnread(notificationId),
      parser: (data) => data,
    );
  }

  Future<void> markAllRead() async {
    await _apiClient.post<Object?>(
      ApiEndpoints.mobileNotificationsReadAll,
      parser: (data) => data,
    );
  }
}
