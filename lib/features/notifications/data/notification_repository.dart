import '../models/notification_model.dart';

/// Repository contract for notification parity.
///
/// API mapping will be connected once the backend notification endpoints are
/// exposed/confirmed.
class NotificationRepository {
  Future<List<NotificationModel>> fetchNotifications() async {
    return const [];
  }

  Future<int> fetchUnreadCount() async {
    return 0;
  }

  Future<void> markAsRead(String id) async {}

  Future<void> markAllAsRead() async {}
}
