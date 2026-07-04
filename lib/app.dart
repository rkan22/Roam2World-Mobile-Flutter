import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/packages/packages_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/esims/esims_screen.dart';
import 'features/wallet/wallet_screen.dart';

class Roam2WorldApp extends StatelessWidget {
  const Roam2WorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/packages',
          builder: (context, state) => const PackagesScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/esims',
          builder: (context, state) => const EsimsScreen(),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const WalletScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Roam2World B2B',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
