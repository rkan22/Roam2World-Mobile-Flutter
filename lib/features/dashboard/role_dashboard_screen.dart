import 'package:flutter/material.dart';

import '../../core/routing/app_role.dart';
import '../auth/auth_repository.dart';
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

    // The premium dashboard remains the visual source of truth. This role-aware
    // entry point lets reseller/dealer-specific slices be introduced without
    // replacing the shared dashboard or duplicating client/public behavior.
    return switch (role) {
      AppRole.reseller || AppRole.dealer => DashboardScreen(
          key: ValueKey<String>('partner-dashboard-${role.name}'),
        ),
      AppRole.client || AppRole.publicUser => const DashboardScreen(
          key: ValueKey<String>('customer-dashboard'),
        ),
      AppRole.admin || AppRole.unknown => const DashboardScreen(
          key: ValueKey<String>('business-dashboard'),
        ),
    };
  }
}
