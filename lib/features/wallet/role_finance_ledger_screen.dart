import 'package:flutter/material.dart';

import '../../core/routing/app_role.dart';
import '../auth/auth_repository.dart';
import 'wallet_screen.dart';

class RoleFinanceLedgerScreen extends StatefulWidget {
  const RoleFinanceLedgerScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<RoleFinanceLedgerScreen> createState() => _RoleFinanceLedgerScreenState();
}

class _RoleFinanceLedgerScreenState extends State<RoleFinanceLedgerScreen> {
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

    // WalletScreen already renders the live dealer/reseller balance semantics
    // from WalletData. Keep it as the visual source of truth and use a
    // role-aware entry point so dedicated finance slices can evolve safely.
    return WalletScreen(
      key: ValueKey<String>('finance-ledger-${role.name}'),
    );
  }
}
