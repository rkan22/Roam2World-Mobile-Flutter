import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
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
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: _ProviderQuickActions(role: role),
            ),
          ),
          Expanded(
            child: DashboardScreen(
              key: ValueKey<String>('approved-demo-dashboard-${role.name}'),
              repository: DashboardRepository(role: role),
              allowDemoFallback: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderQuickActions extends StatelessWidget {
  const _ProviderQuickActions({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    if (role != AppRole.reseller && role != AppRole.dealer) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: B2BShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  label: 'GB Query',
                  icon: Icons.data_usage_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push('/provider-tools/usage'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  label: 'Renew / Top-up',
                  icon: Icons.autorenew_rounded,
                  color: AppColors.success,
                  onTap: () => context.push('/provider-tools/renew'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
