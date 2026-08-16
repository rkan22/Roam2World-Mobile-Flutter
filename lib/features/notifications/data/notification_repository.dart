import '../notification_data.dart';
import '../notifications_repository.dart';

class NotificationRepository {
  NotificationRepository({NotificationsRepository? repository})
    : _repository = repository ?? NotificationsRepository();

  final NotificationsRepository _repository;

  Future<List<MobileNotificationItem>> fetchNotifications() {
    return _repository.fetchNotifications();
  }

  Future<int> fetchUnreadCount() async {
    final items = await _repository.fetchNotifications();
    return items.where((item) => !item.isRead).length;
  }

  Future<void> markAsRead(String id) {
    return _repository.markRead(int.parse(id));
  }

  Future<void> markAllAsRead() {
    return _repository.markAllRead();
  }
}
