import 'package:go_router/go_router.dart';
import '../../features/sim_cards/sim_card_order_history_screen.dart';
import '../../features/sim_cards/sim_cards_screen.dart';
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
import '../../features/esims/tgt_bulk_operations_screen.dart';
import '../../features/admin/admin_commercial_screen.dart';
import '../../features/admin/admin_governance_screen.dart';
import '../../features/admin/admin_partners_screen.dart';
import '../../features/admin/admin_routing_screen.dart';
import '../../features/admin/admin_whatsapp_screen.dart';
import '../../features/admin/manual_fulfillment_screen.dart';
import '../../features/admin/provider_callback_logs_screen.dart';
import '../../features/admin/provider_health_screen.dart';
import '../../features/admin/provider_retry_screen.dart';
import '../../features/notifications/notification_rules_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/nekoko/nekoko_lpa_screen.dart';
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
import '../../features/sim_converter/remote_sim_agent_screen.dart';
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
  static const tgtBulkOperations = '/esims/tgt-bulk';
  static const orders = '/orders';
  static const orderDetail = '/orders/detail';
  static const profile = '/profile';
  static const wallet = '/wallet';
  static const simCards = '/sim-cards';
  static const simCardOrders = '/sim-cards/orders';
  static const reports = '/reports';
  static const notifications = '/notifications';
  static const nekokoLpa = '/nekoko-lpa';
  static const notificationRules = '/notifications/rules';
  static const operations = '/operations';
  static const simConverter = '/sim-converter';
  static const remoteSimAgent = '/sim-converter/remote-agent';
  static const settings = '/settings';
  static const support = '/support';
}

GoRouter createAppRouter({String initialLocation = AppRoutes.onboarding}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
        GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
        GoRoute(path: AppRoutes.dashboard, builder: (_, _) => const RoleDashboardScreen()),
        GoRoute(path: AppRoutes.packages, builder: (_, _) => const PackagesScreen()),
        GoRoute(path: AppRoutes.packageDetail, redirect: (_, s) => s.extra is MobilePackage ? null : AppRoutes.packages, builder: (_, s) => PackageDetailScreen(package: s.extra! as MobilePackage)),
        GoRoute(path: AppRoutes.checkout, redirect: (_, s) => s.extra is MobilePackage ? null : AppRoutes.packages, builder: (_, s) => CheckoutScreen(package: s.extra! as MobilePackage)),
        GoRoute(path: AppRoutes.checkoutSuccess, redirect: (_, s) => s.extra is MobileOrderResult ? null : AppRoutes.orders, builder: (_, s) => OrderSuccessScreen(result: s.extra! as MobileOrderResult)),
        GoRoute(path: AppRoutes.customers, builder: (_, _) => const CustomersScreen()),
        GoRoute(path: AppRoutes.clients, builder: (_, _) => const CustomersScreen()),
        GoRoute(path: AppRoutes.dealerNetwork, builder: (_, _) => const DealerNetworkScreen()),
        GoRoute(path: AppRoutes.adminResellers, builder: (_, _) => const AdminPartnersScreen(type: AdminPartnerType.resellers)),
        GoRoute(path: AppRoutes.adminDealers, builder: (_, _) => const AdminPartnersScreen(type: AdminPartnerType.dealers)),
        GoRoute(path: AppRoutes.adminCommercial, builder: (_, _) => const AdminCommercialScreen()),
        GoRoute(path: AppRoutes.adminProviderRetry, builder: (_, _) => const ProviderRetryScreen()),
        GoRoute(path: AppRoutes.adminProviderCallbacks, builder: (_, _) => const ProviderCallbackLogsScreen()),
        GoRoute(path: AppRoutes.adminProviderHealth, builder: (_, _) => const ProviderHealthScreen()),
        GoRoute(path: AppRoutes.adminRouting, builder: (_, _) => const AdminRoutingScreen()),
        GoRoute(path: AppRoutes.adminManualFulfillment, builder: (_, _) => const ManualFulfillmentScreen()),
        GoRoute(path: AppRoutes.adminGovernance, builder: (_, _) => const AdminGovernanceScreen()),
        GoRoute(path: AppRoutes.adminWhatsApp, builder: (_, _) => const AdminWhatsAppScreen()),
        GoRoute(path: AppRoutes.customerPricing, builder: (_, _) => const CustomerPricingScreen()),
        GoRoute(path: AppRoutes.dealerPricing, builder: (_, _) => const DealerPricingScreen()),
        GoRoute(path: AppRoutes.finance, builder: (_, _) => const RoleFinanceLedgerScreen()),
        GoRoute(path: AppRoutes.esims, builder: (_, _) => const EsimsScreen()),
        GoRoute(path: AppRoutes.esimHistory, builder: (_, _) => const EsimHistoryScreen()),
        GoRoute(path: AppRoutes.tgtBulkOperations, builder: (_, _) => const TgtBulkOperationsScreen()),
        GoRoute(path: AppRoutes.esimDetail, redirect: (_, s) => s.extra is MobileEsim ? null : AppRoutes.esims, builder: (_, s) => EsimDetailScreen(initialEsim: s.extra! as MobileEsim)),
        GoRoute(path: AppRoutes.orders, builder: (_, _) => const OrdersScreen()),
        GoRoute(path: AppRoutes.orderDetail, redirect: (_, s) => s.extra is MobileOrderSummary ? null : AppRoutes.orders, builder: (_, s) => OrderDetailScreen(order: s.extra! as MobileOrderSummary)),
        GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),
        GoRoute(path: AppRoutes.wallet, builder: (_, _) => const WalletScreen()),
        GoRoute(path: AppRoutes.simCards, builder: (_, _) => const SimCardsScreen()),
        GoRoute(path: AppRoutes.simCardOrders, builder: (_, _) => const SimCardOrderHistoryScreen()),
        GoRoute(path: AppRoutes.reports, builder: (_, _) => const ReportsScreen()),
        GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
        GoRoute(path: AppRoutes.nekokoLpa, builder: (_, s) => NekokoLpaScreen(activationCode: s.extra is String ? s.extra! as String : null)),
        GoRoute(path: AppRoutes.notificationRules, builder: (_, _) => const NotificationRulesScreen()),
        GoRoute(path: AppRoutes.operations, builder: (_, _) => const OperationsCenterScreen()),
        GoRoute(path: AppRoutes.simConverter, builder: (_, _) => const SimConverterScreen()),
        GoRoute(path: AppRoutes.remoteSimAgent, builder: (_, _) => const RemoteSimAgentScreen()),
        GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
        GoRoute(path: AppRoutes.support, builder: (_, _) => const SupportScreen()),
      ],
    );
