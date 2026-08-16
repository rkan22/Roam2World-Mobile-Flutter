import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/notifications/push_route_resolver.dart';
import 'package:roam2world_mobile_flutter/core/routing/app_router.dart';

void main() {
  test('maps operational notification events to safe app routes', () {
    expect(
      resolvePushRoute({'notification_event': 'wallet_request_approved'}),
      AppRoutes.finance,
    );
    expect(
      resolvePushRoute({'notification_event': 'order_completed'}),
      AppRoutes.orders,
    );
    expect(
      resolvePushRoute({'notification_event': 'usage_80_percent'}),
      AppRoutes.esims,
    );
  });

  test('does not navigate to an arbitrary payload URL', () {
    expect(
      resolvePushRoute({'action_url': 'https://malicious.example/path'}),
      AppRoutes.notifications,
    );
  });
}
