class ApiEndpoints {
  const ApiEndpoints._();

  static const String mobileLogin = '/api/v1/mobile/auth/login/';
  static const String mobileDashboard = '/api/v1/mobile/dashboard/';
  static const String mobilePackages = '/api/v1/mobile/packages/';
  static const String mobileFeaturedPackages =
      '/api/v1/mobile/packages/featured/';
  static const String mobileOrders = '/api/v1/mobile/orders/';
  static const String mobileEsims = '/api/v1/mobile/esims/';
  static const String mobileWallet = '/api/v1/mobile/wallet/';
  static const String mobileTransactions =
      '/api/v1/mobile/transactions/';
  static const String mobileNotifications =
      '/api/v1/mobile/notifications/';

  static String mobileOrderDetail(Object orderId) =>
      '/api/v1/mobile/orders/$orderId/';

  static String mobileEsimDetail(Object esimId) =>
      '/api/v1/mobile/esims/$esimId/';
}
