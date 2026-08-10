import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/order_success_screen.dart';
import '../../features/customers/clients_home_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/dashboard/role_dashboard_screen.dart';
import '../../features/esims/esim_catalog.dart';
import '../../features/esims/esim_detail_screen.dart';
import '../../features/esims/esims_screen.dart';
import '../../features/notifications/notification_rules_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/operations/operations_center_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/order_history.dart';
import '../../features/orders/order_result.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/packages/catalog_controls_screen.dart';
import '../../features/packages/coverage_screen.dart';
import '../../features/packages/package_catalog.dart';
import '../../features/packages/package_detail_screen.dart';
import '../../features/packages/packages_screen.dart';
import '../../features/partners/dealer_network_screen.dart';
import '../../features/pricing/customer_pricing_screen.dart';
import '../../features/pricing/dealer_pricing_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/reports/dealer_performance_screen.dart';
import '../../features/reports/profitability_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/wallet/role_finance_ledger_screen.dart';

abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const packages = '/packages';
  static const packageDetail = '/packages/detail';
  static const catalogControls = '/catalog-controls';
  static const coverage = '/coverage';
  static const checkout = '/checkout';
  static const checkoutSuccess = '/checkout/success';
  static const clients = '/clients';
  static const customers = '/customers';
  static const customerDetail = '/customers/detail';
  static const dealers = '/dealers';
  static const dealerPricing = '/dealers/pricing';
  static const customerPricing = '/pricing/customer';
  static const dealerPerformance = '/reports/dealers';
  static const profitability = '/reports/profitability';
  static const operations = '/operations';
  static const esims = '/esims';
  static const esimDetail = '/esims/detail';
  static const orders = '/orders';
  static const orderDetail = '/orders/detail';
  static const profile = '/profile';
  static const wallet = '/wallet';
  static const reports = '/reports';
  static const notifications = '/notifications';
  static const notificationRules = '/notifications/rules';
  static const settings = '/settings';
  static const support = '/support';
}

GoRouter createAppRouter({String initialLocation = AppRoutes.onboarding}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const RoleDashboardScreen()),
      GoRoute(path: AppRoutes.packages, builder: (context, state) => const PackagesScreen()),
      GoRoute(path: AppRoutes.catalogControls, builder: (context, state) => const CatalogControlsScreen()),
      GoRoute(path: AppRoutes.coverage, builder: (context, state) => const CoverageScreen()),
      GoRoute(
        path: AppRoutes.packageDetail,
        redirect: (context, state) => state.extra is MobilePackage ? null : AppRoutes.packages,
        builder: (context, state) => PackageDetailScreen(package: state.extra! as MobilePackage),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        redirect: (context, state) => state.extra is MobilePackage ? null : AppRoutes.packages,
        builder: (context, state) => CheckoutScreen(package: state.extra! as MobilePackage),
      ),
      GoRoute(
        path: AppRoutes.checkoutSuccess,
        redirect: (context, state) => state.extra is MobileOrderResult ? null : AppRoutes.orders,
        builder: (context, state) => OrderSuccessScreen(result: state.extra! as MobileOrderResult),
      ),
      GoRoute(path: AppRoutes.clients, builder: (context, state) => const ClientsHomeScreen()),
      GoRoute(path: AppRoutes.customers, builder: (context, state) => const CustomersScreen()),
      GoRoute(
        path: AppRoutes.customerDetail,
        redirect: (context, state) => state.extra is CustomerDetailArgs ? null : AppRoutes.clients,
        builder: (context, state) => CustomerDetailScreen(customer: state.extra! as CustomerDetailArgs),
      ),
      GoRoute(path: AppRoutes.dealers, builder: (context, state) => const DealerNetworkScreen()),
      GoRoute(path: AppRoutes.dealerPricing, builder: (context, state) => const DealerPricingScreen()),
      GoRoute(path: AppRoutes.customerPricing, builder: (context, state) => const CustomerPricingScreen()),
      GoRoute(path: AppRoutes.dealerPerformance, builder: (context, state) => const DealerPerformanceScreen()),
      GoRoute(path: AppRoutes.profitability, builder: (context, state) => const ProfitabilityScreen()),
      GoRoute(path: AppRoutes.operations, builder: (context, state) => const OperationsCenterScreen()),
      GoRoute(path: AppRoutes.esims, builder: (context, state) => const EsimsScreen()),
      GoRoute(
        path: AppRoutes.esimDetail,
        redirect: (context, state) => state.extra is MobileEsim ? null : AppRoutes.esims,
        builder: (context, state) => EsimDetailScreen(initialEsim: state.extra! as MobileEsim),
      ),
      GoRoute(path: AppRoutes.orders, builder: (context, state) => const OrdersScreen()),
      GoRoute(
        path: AppRoutes.orderDetail,
        redirect: (context, state) => state.extra is MobileOrderSummary ? null : AppRoutes.orders,
        builder: (context, state) => OrderDetailScreen(order: state.extra! as MobileOrderSummary),
      ),
      GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
      GoRoute(path: AppRoutes.wallet, builder: (context, state) => const RoleFinanceLedgerScreen()),
      GoRoute(path: AppRoutes.reports, builder: (context, state) => const ReportsScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.notificationRules, builder: (context, state) => const NotificationRulesScreen()),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: AppRoutes.support, builder: (context, state) => const SupportScreen()),
    ],
  );
}
