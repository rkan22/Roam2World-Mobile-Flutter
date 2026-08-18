import '../routing/app_router.dart';

String resolvePushRoute(Map<String, dynamic> data) {
  final raw = (data['action_url'] ?? data['actionUrl'] ?? '')
      .toString()
      .toLowerCase();
  final event =
      (data['notification_event'] ?? data['event'] ?? data['type'] ?? '')
          .toString()
          .toLowerCase();
  final orderId = (data['related_order_id'] ?? data['order_id'] ?? '')
      .toString()
      .trim();
  final orderNumber = (data['order_number'] ?? '').toString().trim();

  if (raw.contains('dealer-wallet')) {
    return AppRoutes.dealerNetwork;
  }

  if (raw.contains('wallet') ||
      event.contains('wallet') ||
      event.contains('balance')) {
    return AppRoutes.finance;
  }
  if (raw.contains('order') ||
      event.contains('order') ||
      event.contains('payment') ||
      event.contains('qr_ready')) {
    if (orderId.isNotEmpty || orderNumber.isNotEmpty) {
      return Uri(
        path: AppRoutes.orders,
        queryParameters: {
          if (orderId.isNotEmpty) 'order_id': orderId,
          if (orderNumber.isNotEmpty) 'order_number': orderNumber,
        },
      ).toString();
    }
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
