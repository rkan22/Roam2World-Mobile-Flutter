import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session.dart';
import '../wallet/wallet_data.dart';
import '../wallet/wallet_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepository = AuthRepository();
  final _walletRepository = WalletRepository();
  AuthSession? _session;
  WalletData? _wallet;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await _authRepository.readStoredProfile();
    WalletData? wallet;
    try {
      wallet = await _walletRepository.fetchWallet();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _session = session;
      _wallet = wallet;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Your secure session will be removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _authRepository.signOut();
    if (mounted) context.go(AppRoutes.login);
  }

  String get _balanceLabel {
    final wallet = _wallet;
    if (wallet == null) return 'Open wallet';
    return '${wallet.currency} ${wallet.availableAmount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 4),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _ProfileHeader(session: _session),
          const SizedBox(height: 20),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.business_outlined,
                title: 'Account type',
                trailing: _session?.role.isNotEmpty == true ? _session!.role : 'Business',
              ),
              _SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Wallet',
                trailing: _balanceLabel,
                onTap: () => context.push(AppRoutes.wallet),
              ),
              _SettingsTile(
                icon: Icons.tune_rounded,
                title: 'App settings',
                trailing: 'English',
                onTap: () => context.push(AppRoutes.settings),
              ),
              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => context.push(AppRoutes.notifications),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & support',
                onTap: () => context.push(AppRoutes.support),
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Security',
                onTap: () => context.push(AppRoutes.settings),
              ),
              const _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Roam2World',
                trailing: 'v1.0.0',
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.session});
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final name = session?.displayName?.trim();
    final title = name?.isNotEmpty == true ? name! : 'Roam2World Account';
    final email = session?.email.isNotEmpty == true ? session!.email : 'Business mobile workspace';
    final initials = title
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final role = session?.role.trim().toLowerCase() ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.navy]),
              ),
              child: Text(
                initials.isEmpty ? 'R2W' : initials,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.success),
                      const SizedBox(width: 5),
                      Text(
                        role.isEmpty ? 'Authenticated account' : 'Verified $role account',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(child: Column(children: children));
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, this.trailing, this.onTap});
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 21, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(trailing!, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
