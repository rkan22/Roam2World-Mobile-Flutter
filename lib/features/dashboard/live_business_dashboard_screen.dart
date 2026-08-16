import 'package:flutter/material.dart';

import '../../core/routing/app_role.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'dashboard_repository.dart';
import 'dashboard_screen_reference.dart';
import 'partner_business_dashboard_screen.dart';

class LiveBusinessDashboardScreen extends StatelessWidget {
  const LiveBusinessDashboardScreen({super.key, required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final repository = DashboardRepository(role: role);
    final partnerRole = role == AppRole.reseller || role == AppRole.dealer;

    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 0),
      body: partnerRole
          ? PartnerBusinessDashboardScreen(
              key: ValueKey<String>('partner-dashboard-${role.name}'),
              role: role,
              repository: repository,
            )
          : DashboardScreen(
              key: ValueKey<String>('approved-dashboard-${role.name}'),
              repository: repository,
              allowDemoFallback: false,
            ),
    );
  }
}
