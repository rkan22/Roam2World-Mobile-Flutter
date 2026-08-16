import '../routing/app_router.dart';

String resolvePushRoute(Map<String, dynamic> data) {
  final raw = (data['action_url'] ?? data['actionUrl'] ?? '')
      .toString()
      .toLowerCase();
  final event =
      (data['notification_event'] ?? data['event'] ?? data['type'] ?? '')
          .toString()
          .toLowerCase();

  if (raw.contains('wallet') ||
      event.contains('wallet') ||
      event.contains('balance')) {
    return AppRoutes.finance;
  }
  if (raw.contains('order') ||
      event.contains('order') ||
      event.contains('qr_ready')) {
    return AppRoutes.orders;
  }
  if (raw.contains('esim') ||
      event.contains('esim') ||
      event.contains('plan_') ||
      event.contains('usage_')) {
    return AppRoutes.esims;
  }
  return AppRoutes.notifications;
}
