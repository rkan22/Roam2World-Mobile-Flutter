import 'package:flutter/material.dart';

import '../../core/routing/app_role.dart';
import '../auth/auth_repository.dart';
import 'business_dashboard_screen.dart';
import 'dashboard_screen_reference.dart';

class RoleDashboardScreen extends StatefulWidget {
  const RoleDashboardScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  late final AuthRepository _authRepository;
  AppRole? _role;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final profile = await _authRepository.readStoredProfile();
    if (!mounted) return;
    setState(() => _role = parseAppRole(profile?.role));
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return switch (role) {
      AppRole.admin || AppRole.reseller || AppRole.dealer => BusinessDashboardScreen(
          key: ValueKey<String>('business-dashboard-${role.name}'),
          role: role,
        ),
      AppRole.client || AppRole.publicUser => const DashboardScreen(
          key: ValueKey<String>('customer-dashboard'),
        ),
      AppRole.unknown => const DashboardScreen(
          key: ValueKey<String>('business-dashboard-unknown'),
        ),
    };
  }
}
