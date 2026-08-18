import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/notifications/push_route_resolver.dart';
import 'package:roam2world_mobile_flutter/core/routing/app_router.dart';

void main() {
  test('dealer wallet approval opens dealer network', () {
    final route = resolvePushRoute({
      'action_url':
          '/reseller-dashboard/dealer-wallet?dealerId=20&requestId=123',
      'notification_event': 'wallet_approval_requested',
    });

    expect(route, AppRoutes.dealerNetwork);
  });

  test('general wallet notification opens finance', () {
    final route = resolvePushRoute({
      'action_url': '/reseller-dashboard/wallet-transactions',
      'notification_event': 'wallet_request_submitted',
    });

    expect(route, AppRoutes.finance);
  });
}
