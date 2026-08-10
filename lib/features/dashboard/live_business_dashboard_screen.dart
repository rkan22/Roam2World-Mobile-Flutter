import 'package:flutter/material.dart';

import '../../core/routing/app_role.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'dashboard_repository.dart';
import 'dashboard_screen_reference.dart';

class LiveBusinessDashboardScreen extends StatelessWidget {
  const LiveBusinessDashboardScreen({
    super.key,
    required this.role,
  });

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 0),
      body: DashboardScreen(
        key: ValueKey<String>('approved-demo-dashboard-${role.name}'),
        repository: DashboardRepository(),
        allowDemoFallback: false,
      ),
    );
  }
}
