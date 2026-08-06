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
          'Your secure session will be removed from this device.',
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
              _AccountHero(
                session: _session,
                wallet: _wallet,
                loading: _loading,
              ),
              const SizedBox(height: B2BSpacing.xl),
              const _SectionTitle('Business workspace'),
              const SizedBox(height: B2BSpacing.md),
              B2BSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AccountTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      subtitle: 'Balance and transaction activity',
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
              const SizedBox(height: B2BSpacing.md),
              B2BSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AccountTile(
                      icon: Icons.tune_rounded,
                      title: 'App settings',
                      subtitle: 'Language, alerts and security',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    const Divider(height: 1),
                    _AccountTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & support',
                      subtitle: 'Get help with your B2B workspace',
                      onTap: () => context.push(AppRoutes.support),
                    ),
                    const Divider(height: 1),
                    const _AccountTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About Roam2World B2B',
                      subtitle: 'Production mobile workspace',
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
                  side: BorderSide(
                    color: AppColors.danger.withValues(alpha: .35),
                  ),
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account center', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: B2BSpacing.xs),
              Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
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
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({
    required this.session,
    required this.wallet,
    required this.loading,
  });

  final AuthSession? session;
  final WalletData? wallet;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final name = session?.displayName?.trim();
    final title = name?.isNotEmpty == true ? name! : 'Roam2World B2B Account';
    final email = session?.email.isNotEmpty == true
        ? session!.email
        : 'Business mobile workspace';
    final role = session?.role.trim().isNotEmpty == true
        ? session!.role.trim()
        : 'Business partner';
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
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: loading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        initials.isEmpty ? 'R2W' : initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: B2BSpacing.xs),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              _HeroMetric(label: 'Account type', value: role),
              const SizedBox(width: B2BSpacing.sm),
              _HeroMetric(label: 'Available funds', value: balance),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          const Row(
            children: [
              Icon(Icons.verified_rounded, size: 18, color: Colors.white),
              SizedBox(width: B2BSpacing.xs),
              Text(
                'Authenticated business account',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(B2BSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(B2BRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
            ),
            const SizedBox(height: B2BSpacing.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
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
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: B2BSpacing.md,
        vertical: B2BSpacing.xs,
      ),
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
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
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
}
