import 'package:flutter/material.dart';

import '../../core/routing/app_role.dart';
import '../auth/auth_repository.dart';
import 'dealer_finance_ledger_screen.dart';
import 'reseller_finance_ledger_screen.dart';

class RoleFinanceLedgerScreen extends StatefulWidget {
  const RoleFinanceLedgerScreen({super.key});

  @override
  State<RoleFinanceLedgerScreen> createState() => _RoleFinanceLedgerScreenState();
}

class _RoleFinanceLedgerScreenState extends State<RoleFinanceLedgerScreen> {
  final _authRepository = AuthRepository();
  AppRole? _role;

  @override
  void initState() {
    super.initState();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (role == AppRole.dealer) return const DealerFinanceLedgerScreen();
    return const ResellerFinanceLedgerScreen();
  }
}
