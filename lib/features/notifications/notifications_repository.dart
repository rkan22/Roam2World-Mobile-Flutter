import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'notification_data.dart';

class NotificationsRepository {
  NotificationsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

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

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? appVersion,
    String? deviceName,
  }) async {
    await _apiClient.post<Object?>(
      ApiEndpoints.mobileDeviceToken,
      data: {
        'token': token.trim(),
        'platform': platform.trim().toLowerCase(),
        if (appVersion?.trim().isNotEmpty == true)
          'app_version': appVersion!.trim(),
        if (deviceName?.trim().isNotEmpty == true)
          'device_name': deviceName!.trim(),
      },
      parser: (data) => data,
    );
  }
}
