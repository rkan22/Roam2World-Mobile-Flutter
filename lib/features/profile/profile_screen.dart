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
        content: const Text(
          'Your secure business session will be removed from this device.',
        ),
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
    return '${_currencySymbol(wallet.currency)}${wallet.availableAmount.toStringAsFixed(2)}';
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
              _IdentityCard(
                session: _session,
                loading: _loading,
              ),
              const SizedBox(height: B2BSpacing.md),
              _AccountOverview(
                role: _session?.role,
                balance: _balanceLabel,
                onWallet: () => context.push(AppRoutes.wallet),
              ),
              const SizedBox(height: B2BSpacing.xl),
              const _SectionTitle(
                title: 'Workspace',
                subtitle: 'Your everyday business tools',
              ),
              const SizedBox(height: B2BSpacing.sm),
              _ActionGrid(
                onWallet: () => context.push(AppRoutes.wallet),
                onReports: () => context.push(AppRoutes.reports),
                onCustomers: () => context.push(AppRoutes.customers),
                onNotifications: () => context.push(AppRoutes.notifications),
              ),
              const SizedBox(height: B2BSpacing.xl),
              const _SectionTitle(
                title: 'Account',
                subtitle: 'Preferences, support and app details',
              ),
              const SizedBox(height: B2BSpacing.sm),
              B2BSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.tune_rounded,
                      title: 'Settings',
                      subtitle: 'Language, appearance and alerts',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & support',
                      subtitle: 'Orders, wallet and installation help',
                      onTap: () => context.push(AppRoutes.support),
                    ),
                    const Divider(height: 1),
                    const _MenuTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Roam2World B2B',
                      subtitle: 'Partner mobile workspace',
                      trailing: 'v1.0.0',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: B2BSpacing.xl),
              B2BSurface(
                padding: const EdgeInsets.all(B2BSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(B2BRadius.md),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: B2BSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign out',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'End this session on this device',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _logout,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      child: const Text('Log out'),
                    ),
                  ],
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
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: B2BSpacing.xxs),
                Text(
                  'Account, workspace and preferences',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.session, required this.loading});

  final AuthSession? session;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final name = session?.displayName?.trim();
    final title = name?.isNotEmpty == true ? name! : 'Roam2World B2B Account';
    final email = session?.email.isNotEmpty == true
        ? session!.email
        : 'Business mobile workspace';
    final role = _roleLabel(session?.role);
    final initials = title
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return B2BSurface(
      padding: const EdgeInsets.all(B2BSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: loading
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    initials.isEmpty ? 'R2W' : initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: B2BSpacing.xxs),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: B2BSpacing.sm),
                Wrap(
                  spacing: B2BSpacing.xs,
                  runSpacing: B2BSpacing.xs,
                  children: [
                    _Pill(
                      icon: Icons.business_center_outlined,
                      label: role,
                    ),
                    const _Pill(
                      icon: Icons.verified_rounded,
                      label: 'Verified account',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(B2BRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _AccountOverview extends StatelessWidget {
  const _AccountOverview({
    required this.role,
    required this.balance,
    required this.onWallet,
  });

  final String? role;
  final String balance;
  final VoidCallback onWallet;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _OverviewCard(
              icon: Icons.badge_outlined,
              label: 'Account type',
              value: _roleLabel(role),
            ),
          ),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(
            child: _OverviewCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Available balance',
              value: balance,
              onTap: onWallet,
            ),
          ),
        ],
      );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => B2BSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(B2BSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(B2BRadius.sm),
              ),
              child: Icon(icon, size: 19, color: AppColors.primary),
            ),
            const SizedBox(height: B2BSpacing.md),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      );
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.onWallet,
    required this.onReports,
    required this.onCustomers,
    required this.onNotifications,
  });

  final VoidCallback onWallet;
  final VoidCallback onReports;
  final VoidCallback onCustomers;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: B2BSpacing.sm,
        crossAxisSpacing: B2BSpacing.sm,
        childAspectRatio: 1.55,
        children: [
          _ActionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: 'Balance & top-ups',
            onTap: onWallet,
          ),
          _ActionCard(
            icon: Icons.analytics_outlined,
            title: 'Reports',
            subtitle: 'Sales & activity',
            onTap: onReports,
          ),
          _ActionCard(
            icon: Icons.people_outline_rounded,
            title: 'Customers',
            subtitle: 'Accounts & orders',
            onTap: onCustomers,
          ),
          _ActionCard(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Account updates',
            onTap: onNotifications,
          ),
        ],
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => B2BSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(B2BSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(B2BRadius.sm),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.primary),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: B2BSpacing.md,
          vertical: B2BSpacing.xs,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(B2BRadius.sm),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing != null
            ? Text(
                trailing!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              )
            : onTap != null
                ? const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  )
                : null,
      );
}

String _roleLabel(String? role) {
  final normalized = role?.trim().toLowerCase() ?? '';
  return switch (normalized) {
    'admin' => 'Admin',
    'reseller' => 'Reseller',
    'dealer' => 'Dealer',
    'client' => 'Client',
    'public' || 'public_user' => 'Public',
    _ => role?.trim().isNotEmpty == true ? role!.trim() : 'Business partner',
  };
}

String _currencySymbol(String currency) {
  return switch (currency.toUpperCase()) {
    'USD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    'TRY' => '₺',
    _ => '${currency.toUpperCase()} ',
  };
}
