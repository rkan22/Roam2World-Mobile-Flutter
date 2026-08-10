import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/order_success_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/dashboard/reseller_dashboard_screen.dart';
import '../../features/esims/esim_catalog.dart';
import '../../features/esims/esim_detail_screen.dart';
import '../../features/esims/esims_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/order_result.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/packages/package_catalog.dart';
import '../../features/packages/package_detail_screen.dart';
import '../../features/packages/packages_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/support/support_screen.dart';
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
  static const customerDetail = '/customers/detail';
  static const esims = '/esims';
  static const esimDetail = '/esims/detail';
  static const orders = '/orders';
  static const orderDetail = '/orders/detail';
  static const profile = '/profile';
  static const wallet = '/wallet';
  static const reports = '/reports';
  static const notifications = '/notifications';
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
      GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const ResellerDashboardScreen()),
      GoRoute(path: AppRoutes.packages, builder: (context, state) => const PackagesScreen()),
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
      GoRoute(path: AppRoutes.customers, builder: (context, state) => const CustomersScreen()),
      GoRoute(
        path: AppRoutes.customerDetail,
        redirect: (context, state) => state.extra is CustomerDetailArgs ? null : AppRoutes.customers,
        builder: (context, state) => CustomerDetailScreen(customer: state.extra! as CustomerDetailArgs),
      ),
      GoRoute(path: AppRoutes.esims, builder: (context, state) => const EsimsScreen()),
      GoRoute(
        path: AppRoutes.esimDetail,
        redirect: (context, state) => state.extra is MobileEsim ? null : AppRoutes.esims,
        builder: (context, state) => EsimDetailScreen(initialEsim: state.extra! as MobileEsim),
      ),
      GoRoute(path: AppRoutes.orders, builder: (context, state) => const OrdersScreen()),
      GoRoute(path: AppRoutes.orderDetail, builder: (context, state) => const OrderDetailScreen()),
      GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
      GoRoute(path: AppRoutes.wallet, builder: (context, state) => const WalletScreen()),
      GoRoute(path: AppRoutes.reports, builder: (context, state) => const ReportsScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: AppRoutes.support, builder: (context, state) => const SupportScreen()),
    ],
  );
}
