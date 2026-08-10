class ApiEndpoints {
  const ApiEndpoints._();

  static const String mobileLogin = '/api/v1/mobile/auth/login/';
  static const String tokenRefresh = '/api/v1/auth/refresh/';
  static const String mobileDashboard = '/api/v1/mobile/dashboard/';
  static const String mobileAdminDashboard = '/api/v1/mobile/admin/dashboard/';
  static const String mobileAdminResellers = '/api/v1/mobile/admin/resellers/';
  static const String mobileAdminDealers = '/api/v1/mobile/admin/dealers/';
  static const String mobileAdminOrders = '/api/v1/mobile/admin/orders/';
  static const String mobileAdminPricing = '/api/v1/mobile/admin/pricing/';
  static const String mobileAdminReports = '/api/v1/mobile/admin/reports/';
  static const String mobileAdminSystemHealth =
      '/api/v1/mobile/admin/system-health/';
  static const String mobileAdminActivityLogs =
      '/api/v1/mobile/admin/activity-logs/';
  static const String mobileAdminSupportTickets =
      '/api/v1/mobile/admin/support-tickets/';
  static const String mobileAdminWhatsApp = '/api/v1/mobile/admin/whatsapp/';
  static const String mobileAdminProviderRetryQueue =
      '/api/v1/mobile/admin/provider-retry-queue/';
  static const String mobileAdminProviderCallbackLogs =
      '/api/v1/mobile/admin/provider-callback-logs/';
  static const String mobileAdminRoutingRules =
      '/api/v1/mobile/admin/routing-rules/';
  static const String mobileAdminRoutingOverride =
      '/api/v1/mobile/admin/routing-rules/override/';
  static const String mobileB2BProviderHealth =
      '/api/v1/mobile/b2b/provider-health/';
  static const String manualAdminProducts =
      '/api/v1/admin/manual-fulfillment/products/';
  static const String manualAdminSimInventory =
      '/api/v1/admin/manual-fulfillment/sim-inventory/';
  static const String manualAdminTasks =
      '/api/v1/admin/manual-fulfillment/tasks/';
  static const String manualCatalogProducts =
      '/api/v1/mobile/b2b/manual/products/';
  static const String manualRequest = '/api/v1/mobile/b2b/manual/request/';
  static const String mobilePackages = '/api/v1/mobile/packages/';
  static const String mobileWorldmovePackages =
      '/api/v1/mobile/worldmove/packages/';
  static const String mobileFeaturedPackages =
      '/api/v1/mobile/packages/featured/';
  static const String mobileOrders = '/api/v1/mobile/orders/';
  static const String mobileEsims = '/api/v1/mobile/esims/';
  static const String mobileEsimHistory = '/api/v1/mobile/esim-history/';
  static const String mobileTgtCheckGb = '/api/v1/mobile/tgt/check-gb/';
  static const String mobileWallet = '/api/v1/mobile/wallet/';
  static const String mobileWalletRequests = '/api/v1/mobile/wallet/requests/';
  static const String mobileTransactions = '/api/v1/mobile/transactions/';
  static const String mobileDealerWalletRequests =
      '/api/v1/mobile/dealer-wallet-requests/';
  static const String mobileResellerWalletRequests =
      '/api/v1/mobile/reseller-wallet-requests/';
  static const String mobileNotifications = '/api/v1/mobile/notifications/';
  static const String mobileNotificationsReadAll =
      '/api/v1/mobile/notifications/read-all/';
  static const String notificationRules = '/api/v1/notifications/rules/';

  static const String dealerBalanceRequest =
      '/api/v1/resellers/dealer-balance/request_balance/';
  static const String dealerBalanceRequests =
      '/api/v1/resellers/dealer-balance/balance_requests/';
  static const String dealerProfile = '/api/v1/resellers/dealers/my_profile/';
  static const String dealerUpdateProfile =
      '/api/v1/resellers/dealers/update_profile/';

  static const String simConverterConversions =
      '/api/v1/sim-converter/conversions/';
  static const String simConverterStatistics =
      '/api/v1/sim-converter/conversions/statistics/';
  static const String simConverterParseActivationCode =
      '/api/v1/sim-converter/conversions/parse_activation_code/';

  static const String resellerDealers = '/api/v1/resellers/dealers/';
  static const String resellerDealerWalletHistory =
      '/api/v1/resellers/dealers/wallet-history/';
  static const String resellerPendingDealerRequests =
      '/api/v1/resellers/dealer-requests/pending/';

  static const String failedOrders = '/api/v1/orders/failed/';
  static const String providerOperationLogs =
      '/api/v1/provider-operations/logs/';
  static const String webhookLogs = '/api/v1/webhooks/logs/';
  static const String auditLogs = '/api/v1/audit/logs/';
  static const String resellerDealerRequests =
      '/api/v1/resellers/dealer-requests/';

  static String mobileOrderDetail(Object orderId) =>
      '/api/v1/mobile/orders/$orderId/';

  static String mobileEsimDetail(Object esimId) =>
      '/api/v1/mobile/esims/$esimId/';

  static String mobileEsimHistoryDetail(Object esimId) =>
      '/api/v1/mobile/esim-history/$esimId/';

  static String mobileNotificationRead(Object notificationId) =>
      '/api/v1/mobile/notifications/$notificationId/read/';

  static String mobileNotificationUnread(Object notificationId) =>
      '/api/v1/mobile/notifications/$notificationId/unread/';

  static String mobileAdminProviderRetryDetail(Object itemId) =>
      '/api/v1/mobile/admin/provider-retry-queue/$itemId/';

  static String mobileAdminProviderRetryAction(Object itemId) =>
      '/api/v1/mobile/admin/provider-retry-queue/$itemId/action/';

  static String mobileAdminProviderCallbackLogDetail(Object logId) =>
      '/api/v1/mobile/admin/provider-callback-logs/$logId/';

  static String mobileAdminRoutingRuleDetail(Object ruleId) =>
      '/api/v1/mobile/admin/routing-rules/$ruleId/';

  static String manualAdminProductDetail(Object packageId) =>
      '/api/v1/admin/manual-fulfillment/products/$packageId/';

  static String manualAdminAssignQr(Object taskId) =>
      '/api/v1/admin/manual-fulfillment/tasks/$taskId/assign-qr/';

  static String manualAdminActivateSim(Object taskId) =>
      '/api/v1/admin/manual-fulfillment/tasks/$taskId/activate-sim/';

  static String manualAdminCancelTask(Object taskId) =>
      '/api/v1/admin/manual-fulfillment/tasks/$taskId/cancel/';

  static String manualAdminSendToFlexnet(Object taskId) =>
      '/api/v1/admin/manual-fulfillment/tasks/$taskId/send-to-flexnet/';

  static String mobileDealerAllocateBalance(Object dealerId) =>
      '/api/v1/mobile/dealers/$dealerId/allocate-balance/';

  static String mobileDealerModifyBalance(Object dealerId) =>
      '/api/v1/mobile/dealers/$dealerId/modify-balance/';

  static String mobileDealerWalletRequestApprove(Object requestId) =>
      '/api/v1/mobile/dealer-wallet-requests/$requestId/approve/';

  static String mobileDealerWalletRequestReject(Object requestId) =>
      '/api/v1/mobile/dealer-wallet-requests/$requestId/reject/';

  static String mobileResellerWalletRequestApprove(Object requestId) =>
      '/api/v1/mobile/reseller-wallet-requests/$requestId/approve/';

  static String mobileResellerWalletRequestReject(Object requestId) =>
      '/api/v1/mobile/reseller-wallet-requests/$requestId/reject/';

  static String adminWalletTopUpAdjust(Object requestId) =>
      '/api/v1/admin/wallet/topups/$requestId/adjust/';

  static String adminWalletTopUpRefund(Object requestId) =>
      '/api/v1/admin/wallet/topups/$requestId/refund/';
}
