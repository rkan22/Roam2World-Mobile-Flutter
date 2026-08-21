class ApiEndpoints {
  const ApiEndpoints._();

  static const String mobileLogin = '/api/v1/mobile/auth/login/';
  static const String tokenRefresh = '/api/v1/auth/refresh/';
  static const String logout = '/api/v1/auth/logout/';
  static const String passwordResetRequest =
      '/api/v1/auth/password-reset-request/';
  static const String passwordResetVerifyOtp = '/api/v1/auth/otp-verify/';
  static const String passwordResetResendOtp = '/api/v1/auth/resend-otp/';
  static const String passwordResetConfirm =
      '/api/v1/auth/password-reset-confirm/';
  static const String passwordChange = '/api/v1/auth/password-change/';
  static const String userProfile = '/api/v1/auth/profile/';
  static const String updateUserProfile = '/api/v1/auth/update-profile/';
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
  static String manualAdminProductDetail(Object packageId) =>
      '$manualAdminProducts${Uri.encodeComponent(packageId.toString())}/';
  static const String manualAdminSimInventory =
      '/api/v1/admin/manual-fulfillment/sim-inventory/';
  static const String manualAdminTasks =
      '/api/v1/admin/manual-fulfillment/tasks/';
  static const String manualCatalogProducts =
      '/api/v1/mobile/b2b/manual/products/';
  static const String manualRequest = '/api/v1/mobile/b2b/manual/request/';
  static const String pricingRules = '/api/v1/pricing-rules/';
  static const String pricingPreview = '/api/v1/pricing/preview/';
  static const String pricingBatchPreview = '/api/v1/pricing/batch-preview/';
  static String pricingRuleDetail(Object ruleId) =>
      '/api/v1/pricing-rules/$ruleId/';
  static const List<String> airhubCatalogSources = [
    '/api/v1/airhub/packages/filtered/',
    '/api/v1/airhub/packages/',
    '/api/v1/providers/airhub/packages/filtered/',
  ];
  static const List<String> flexnetCatalogSources = [
    '/api/v1/mobile/b2b/flexnet/big-data/packages/',
  ];
  static const List<String> tgtCatalogSources = [
    '/api/v1/mobile/b2b/tgt/balkans/packages/',
    '/api/v1/mobile/smart/packages/',
  ];
  static const String mobilePackages = '/api/v1/mobile/packages/';
  static const String mobileWorldmovePackages =
      '/api/v1/mobile/worldmove/packages/';
  static const String mobileWorldmoveOrders =
      '/api/v1/mobile/worldmove/orders/';
  static const String mobileFeaturedPackages =
      '/api/v1/mobile/packages/featured/';
  static const String mobileOrders = '/api/v1/mobile/orders/';
  static const String mobileEsims = '/api/v1/mobile/esims/';
  static const String resellerClients = '/api/v1/esim/reseller/clients/';
  static const String dealerClients = '/api/v1/esim/dealer/clients/';
  static const String mobileEsimHistory = '/api/v1/mobile/esim-history/';
  static const String mobileTgtCheckGb = '/api/v1/mobile/tgt/check-gb/';
  static const String mobileTgtRenew = '/api/v1/mobile/tgt/esim/renew/';
  static String mobileTgtRenewalOptions(Object esimId) =>
      '/api/v1/mobile/tgt/esim/$esimId/renewal-options/';
  static const String mobileWorldmoveTopup = '/api/v1/mobile/worldmove/topup/';
  static const String mobileWorldmoveUsage = '/api/v1/worldmove/usage-status/';
  static const String mobileAirhubUsageCheck =
      '/api/v1/mobile/b2b/airhub/usage-check/';
  static const String mobileEsimcardUsageCheck =
      '/api/v1/mobile/b2b/esimcard/usage-check/';
  static const String mobileEsimcardTopupCheckout =
      '/api/v1/mobile/b2b/esimcard/topup-checkout/';
  static const String mobileSmartHealth = '/api/v1/mobile/smart/health/';
  static const String mobileSmartCategories =
      '/api/v1/mobile/smart/categories/';
  static const String mobileSmartPackages = '/api/v1/mobile/smart/packages/';
  static const String mobileSmartCreateOrder =
      '/api/v1/mobile/smart/orders/create/';
  static const String mobileSmartCheckout = '/api/v1/mobile/smart/checkout/';
  static const String mobileSmartOrders = '/api/v1/mobile/smart/orders/';
  static String mobileSmartOrderDetail(Object orderId) =>
      '/api/v1/mobile/smart/orders/$orderId/';
  static const String mobileSmartUsageCheck =
      '/api/v1/mobile/smart/usage-check/';
  static const String mobileSimPackages = '/api/v1/mobile/packages/';
  static const String mobileSimOrders = '/api/v1/mobile/orders/';
  static const String mobileSimOrderHistory = '/api/v1/mobile/orders/';
  static const String mobileSmartWalletStatus =
      '/api/v1/mobile/smart/wallet/status/';
  static const String mobileSmartWalletChargeOrder =
      '/api/v1/mobile/smart/wallet/charge-order/';
  static const String mobileSmartWalletRefundOrder =
      '/api/v1/mobile/smart/wallet/refund-order/';
  static const String mobileSmartWalletTransactions =
      '/api/v1/mobile/smart/wallet/transactions/';
  static const String mobileTgtBulkTopup =
      '/api/v1/mobile/b2b/tgt/balkans/bulk-topup/';
  static const String mobileTgtBulkActivate =
      '/api/v1/mobile/b2b/tgt/balkans/bulk-activate/';
  static const String mobileDeviceToken = '/api/v1/mobile/device-token/';
  static const String mobileVodafoneRenew =
      '/api/v1/mobile/airhub/vodafone/renew/';
  static String mobileVodafoneRenewalOptions(Object esimId) =>
      '/api/v1/mobile/airhub/vodafone/$esimId/renewal-options/';
  static const String mobileWallet = '/api/v1/mobile/wallet/';
  static const String mobileWalletRequests = '/api/v1/mobile/wallet/requests/';
  static const String mobileTransactions = '/api/v1/mobile/transactions/';
  static const String providerAllocations = '/api/v1/credits/my-allocations/';
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
  static String mobileFlexnetEsimSync(Object esimId) =>
      '/api/v1/mobile/b2b/flexnet/esims/$esimId/sync/';
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
  static String mobileAdminResellerMarkup(Object resellerId) =>
      '/api/v1/mobile/admin/resellers/$resellerId/markup/';
  static String mobileAdminDealerMarkup(Object dealerId) =>
      '/api/v1/mobile/admin/dealers/$dealerId/markup/';
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
  static String mobileDealerSuspend(Object dealerId) =>
      '/api/v1/mobile/dealers/$dealerId/suspend/';
  static String mobileDealerActivate(Object dealerId) =>
      '/api/v1/mobile/dealers/$dealerId/activate/';
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
