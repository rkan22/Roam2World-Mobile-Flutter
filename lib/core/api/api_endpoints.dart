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

  static String mobileOrderDetail(Object orderId) =>
      '/api/v1/mobile/orders/$orderId/';

  static String mobileEsimDetail(Object esimId) =>
      '/api/v1/mobile/esims/$esimId/';

  static String mobileNotificationRead(Object notificationId) =>
      '/api/v1/mobile/notifications/$notificationId/read/';

  static String mobileNotificationUnread(Object notificationId) =>
      '/api/v1/mobile/notifications/$notificationId/unread/';
}
