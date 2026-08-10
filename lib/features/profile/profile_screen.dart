import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = _session == null);
    final session = await _authRepository.readStoredProfile();
    WalletData? wallet;
    try {
      wallet = await _walletRepository.fetchWallet();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _session = session;
      _wallet = wallet;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Your secure business session will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
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
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              B2BSpacing.lg,
              B2BSpacing.md,
              B2BSpacing.lg,
              B2BSpacing.xxl,
            ),
            children: [
              _Header(onRefresh: _load),
              const SizedBox(height: B2BSpacing.lg),
              _AccountHero(session: _session, wallet: _wallet, loading: _loading),
              const SizedBox(height: B2BSpacing.lg),
              _QuickLinks(
                onWallet: () => context.push(AppRoutes.wallet),
                onReports: () => context.push(AppRoutes.reports),
                onCustomers: () => context.push(AppRoutes.customers),
              ),
              const SizedBox(height: B2BSpacing.xl),
              const _SectionTitle('Business workspace'),
              const SizedBox(height: B2BSpacing.sm),
              B2BSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AccountTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      subtitle: 'Balance, top-ups and transactions',
                      trailing: _balanceLabel,
                      onTap: () => context.push(AppRoutes.wallet),
                    ),
                    const Divider(height: 1),
                    _AccountTile(
                      icon: Icons.analytics_outlined,
                      title: 'Business reports',
                      subtitle: 'Sales, orders and eSIM performance',
                      trailing: 'Live',
                      onTap: () => context.push(AppRoutes.reports),
                    ),
                    const Divider(height: 1),
                    _AccountTile(
                      icon: Icons.people_outline_rounded,
                      title: 'Customers',
                      subtitle: 'Customer activity and order history',
                      onTap: () => context.push(AppRoutes.customers),
                    ),
                    const Divider(height: 1),
                    _AccountTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Operational and account updates',
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: B2BSpacing.xl),
              const _SectionTitle('Account & support'),
              const SizedBox(height: B2BSpacing.sm),
              B2BSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AccountTile(
                      icon: Icons.tune_rounded,
                      title: 'Settings',
                      subtitle: 'Language, appearance and alerts',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    const Divider(height: 1),
                    _AccountTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & support',
                      subtitle: 'Installation, orders, wallet and support',
                      onTap: () => context.push(AppRoutes.support),
                    ),
                    const Divider(height: 1),
                    const _AccountTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Roam2World B2B',
                      subtitle: 'Secure reseller mobile workspace',
                      trailing: 'v1.0.0',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: B2BSpacing.xl),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out securely'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withValues(alpha: .35)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Business account', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: B2BSpacing.xxs),
                Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onRefresh,
            tooltip: 'Refresh profile',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      );
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({required this.session, required this.wallet, required this.loading});

  final AuthSession? session;
  final WalletData? wallet;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final name = session?.displayName?.trim();
    final title = name?.isNotEmpty == true ? name! : 'Roam2World B2B Account';
    final email = session?.email.isNotEmpty == true ? session!.email : 'Business mobile workspace';
    final role = session?.role.trim().isNotEmpty == true ? session!.role.trim() : 'Business partner';
    final initials = title
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final balance = wallet == null
        ? 'Wallet unavailable'
        : '${wallet!.currency} ${wallet!.availableAmount.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(B2BSpacing.xl),
      decoration: BoxDecoration(
        gradient: B2BGradients.primary,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        boxShadow: B2BShadows.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white24),
                ),
                child: loading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        initials.isEmpty ? 'R2W' : initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: B2BSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: B2BSpacing.xxs),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(B2BRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Verified', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(child: _HeroMetric(label: 'Account type', value: role)),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(child: _HeroMetric(label: 'Available funds', value: balance)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(B2BSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(B2BRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
            const SizedBox(height: B2BSpacing.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.onWallet, required this.onReports, required this.onCustomers});
  final VoidCallback onWallet;
  final VoidCallback onReports;
  final VoidCallback onCustomers;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: _QuickLink(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', onTap: onWallet)),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(child: _QuickLink(icon: Icons.analytics_outlined, label: 'Reports', onTap: onReports)),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(child: _QuickLink(icon: Icons.people_outline_rounded, label: 'Customers', onTap: onCustomers)),
        ],
      );
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => B2BSurface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: B2BSpacing.md, horizontal: B2BSpacing.xs),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: B2BSpacing.xs),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: B2BSpacing.md, vertical: B2BSpacing.xs),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(B2BRadius.sm),
          ),
          child: Icon(icon, size: 21, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  trailing!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                ),
              ),
            if (onTap != null) ...[
              const SizedBox(width: B2BSpacing.xs),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ],
        ),
      );
}
