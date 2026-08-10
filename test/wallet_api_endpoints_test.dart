import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/api/api_endpoints.dart';

void main() {
  test('builds role-scoped wallet review endpoints', () {
    expect(
      ApiEndpoints.mobileDealerWalletRequestReject(12),
      '/api/v1/mobile/dealer-wallet-requests/12/reject/',
    );
    expect(
      ApiEndpoints.mobileResellerWalletRequestApprove(13),
      '/api/v1/mobile/reseller-wallet-requests/13/approve/',
    );
  });

  test('builds admin adjustment and refund endpoints', () {
    expect(
      ApiEndpoints.adminWalletTopUpAdjust(20),
      '/api/v1/admin/wallet/topups/20/adjust/',
    );
    expect(
      ApiEndpoints.adminWalletTopUpRefund(20),
      '/api/v1/admin/wallet/topups/20/refund/',
    );
  });
}
