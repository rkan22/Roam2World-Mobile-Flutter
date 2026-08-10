import 'package:go_router/go_router.dart';

import '../../features/admin/admin_commercial_screen.dart';
import '../../features/admin/admin_governance_screen.dart';
import '../../features/admin/admin_partners_screen.dart';
import '../../features/admin/admin_routing_screen.dart';
import '../../features/admin/admin_whatsapp_screen.dart';
import '../../features/admin/manual_fulfillment_screen.dart';
import '../../features/admin/provider_callback_logs_screen.dart';
import '../../features/admin/provider_health_screen.dart';
import '../../features/admin/provider_retry_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/order_success_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/dashboard/role_dashboard_screen.dart';
import '../../features/esims/esim_catalog.dart';
import '../../features/esims/esim_detail_screen.dart';
import '../../features/esims/esim_history_screen.dart';
import '../../features/esims/esims_screen.dart';
import '../../features/notifications/notification_rules_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/operations/operations_center_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/order_history.dart';
import '../../features/orders/order_result.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/packages/package_catalog.dart';
import '../../features/packages/package_detail_screen.dart';
import '../../features/packages/packages_screen.dart';
import '../../features/partners/dealer_network_screen.dart';
import '../../features/pricing/customer_pricing_screen.dart';
import '../../features/pricing/dealer_pricing_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/sim_converter/sim_converter_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/wallet/role_finance_ledger_screen.dart';
import '../../features/wallet/wallet_screen.dart';

abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const packages = '/packages';
  static const packageDetail = '/packages/detail';
  static const checkout = '/checkout';
  static const checkoutSuccess = '/checkout/success';
  static const customers = '/customers';
  static const clients = '/clients';
  static const dealerNetwork = '/dealers';
  static const adminResellers = '/admin/resellers';
  static const adminDealers = '/admin/dealers';
  static const adminCommercial = '/admin/commercial';
  static const adminProviderRetry = '/admin/provider-retry';
  static const adminProviderCallbacks = '/admin/provider-callbacks';
  static const adminProviderHealth = '/admin/provider-health';
  static const adminRouting = '/admin/routing';
  static const adminManualFulfillment = '/admin/manual-fulfillment';
  static const adminGovernance = '/admin/governance';
  static const adminWhatsApp = '/admin/whatsapp';
  static const customerPricing = '/pricing/customer';
  static const dealerPricing = '/dealers/pricing';
  static const finance = '/finance';
  static const esims = '/esims';
  static const esimDetail = '/esims/detail';
  static const esimHistory = '/esims/history';
  static const orders = '/orders';
  static const orderDetail = '/orders/detail';
  static const profile = '/profile';
  static const wallet = '/wallet';
  static const reports = '/reports';
  static const notifications = '/notifications';
  static const notificationRules = '/notifications/rules';
  static const operations = '/operations';
  static const simConverter = '/sim-converter';
  static const settings = '/settings';
  static const support = '/support';
}

GoRouter createAppRouter({String initialLocation = AppRoutes.onboarding}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const RoleDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.packages,
        builder: (context, state) => const PackagesScreen(),
      ),
      GoRoute(
        path: AppRoutes.packageDetail,
        redirect: (context, state) =>
            state.extra is MobilePackage ? null : AppRoutes.packages,
        builder: (context, state) =>
            PackageDetailScreen(package: state.extra! as MobilePackage),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        redirect: (context, state) =>
            state.extra is MobilePackage ? null : AppRoutes.packages,
        builder: (context, state) =>
            CheckoutScreen(package: state.extra! as MobilePackage),
      ),
      GoRoute(
        path: AppRoutes.checkoutSuccess,
        redirect: (context, state) =>
            state.extra is MobileOrderResult ? null : AppRoutes.orders,
        builder: (context, state) =>
            OrderSuccessScreen(result: state.extra! as MobileOrderResult),
      ),
      GoRoute(
        path: AppRoutes.customers,
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: AppRoutes.clients,
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: AppRoutes.dealerNetwork,
        builder: (context, state) => const DealerNetworkScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminResellers,
        builder: (context, state) =>
            const AdminPartnersScreen(type: AdminPartnerType.resellers),
      ),
      GoRoute(
        path: AppRoutes.adminDealers,
        builder: (context, state) =>
            const AdminPartnersScreen(type: AdminPartnerType.dealers),
      ),
      GoRoute(
        path: AppRoutes.adminCommercial,
        builder: (context, state) => const AdminCommercialScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProviderRetry,
        builder: (context, state) => const ProviderRetryScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProviderCallbacks,
        builder: (context, state) => const ProviderCallbackLogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProviderHealth,
        builder: (context, state) => const ProviderHealthScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminRouting,
        builder: (context, state) => const AdminRoutingScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminManualFulfillment,
        builder: (context, state) => const ManualFulfillmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGovernance,
        builder: (context, state) => const AdminGovernanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminWhatsApp,
        builder: (context, state) => const AdminWhatsAppScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerPricing,
        builder: (context, state) => const CustomerPricingScreen(),
      ),
      GoRoute(
        path: AppRoutes.dealerPricing,
        builder: (context, state) => const DealerPricingScreen(),
      ),
      GoRoute(
        path: AppRoutes.finance,
        builder: (context, state) => const RoleFinanceLedgerScreen(),
      ),
      GoRoute(
        path: AppRoutes.esims,
        builder: (context, state) => const EsimsScreen(),
      ),
      GoRoute(
        path: AppRoutes.esimHistory,
        builder: (context, state) => const EsimHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.esimDetail,
        redirect: (context, state) =>
            state.extra is MobileEsim ? null : AppRoutes.esims,
        builder: (context, state) =>
            EsimDetailScreen(initialEsim: state.extra! as MobileEsim),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        redirect: (context, state) =>
            state.extra is MobileOrderSummary ? null : AppRoutes.orders,
        builder: (context, state) =>
            OrderDetailScreen(order: state.extra! as MobileOrderSummary),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationRules,
        builder: (context, state) => const NotificationRulesScreen(),
      ),
      GoRoute(
        path: AppRoutes.operations,
        builder: (context, state) => const OperationsCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.simConverter,
        builder: (context, state) => const SimConverterScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (context, state) => const SupportScreen(),
      ),
    ],
  );
}
