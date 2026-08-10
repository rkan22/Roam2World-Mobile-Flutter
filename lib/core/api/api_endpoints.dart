class ApiEndpoints {
  const ApiEndpoints._();

  static const String mobileLogin = '/api/v1/mobile/auth/login/';
  static const String tokenRefresh = '/api/v1/auth/refresh/';
  static const String mobileDashboard = '/api/v1/mobile/dashboard/';
  static const String mobilePackages = '/api/v1/mobile/packages/';
  static const String mobileFeaturedPackages =
      '/api/v1/mobile/packages/featured/';
  static const String mobileOrders = '/api/v1/mobile/orders/';
  static const String mobileEsims = '/api/v1/mobile/esims/';
  static const String mobileWallet = '/api/v1/mobile/wallet/';
  static const String mobileWalletRequests =
      '/api/v1/mobile/wallet/requests/';
  static const String mobileTransactions =
      '/api/v1/mobile/transactions/';
  static const String mobileNotifications =
      '/api/v1/mobile/notifications/';
  static const String mobileNotificationsReadAll =
      '/api/v1/mobile/notifications/read-all/';

  // Reseller -> dealer network endpoints used by the web B2B panel.
  static const String resellerDealers = '/api/v1/resellers/dealers/';
  static const String resellerDealerWalletHistory =
      '/api/v1/resellers/dealers/wallet-history/';
  static const String resellerPendingDealerRequests =
      '/api/v1/resellers/dealer-requests/pending/';

  static String mobileOrderDetail(Object orderId) =>
      '/api/v1/mobile/orders/$orderId/';

  static String mobileEsimDetail(Object esimId) =>
      '/api/v1/mobile/esims/$esimId/';

  static String mobileNotificationRead(Object notificationId) =>
      '/api/v1/mobile/notifications/$notificationId/read/';

  static String mobileNotificationUnread(Object notificationId) =>
      '/api/v1/mobile/notifications/$notificationId/unread/';

  static String mobileDealerAllocateBalance(Object dealerId) =>
      '/api/v1/mobile/dealers/$dealerId/allocate-balance/';

  static String mobileDealerModifyBalance(Object dealerId) =>
      '/api/v1/mobile/dealers/$dealerId/modify-balance/';

  static String mobileDealerWalletRequestApprove(Object requestId) =>
      '/api/v1/mobile/dealer-wallet-requests/$requestId/approve/';
}
