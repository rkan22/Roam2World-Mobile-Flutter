import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_role.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../features/auth/auth_repository.dart';

class R2WBottomNav extends StatefulWidget {
  const R2WBottomNav({super.key, required this.selectedIndex});
  final int selectedIndex;
  @override
  State<R2WBottomNav> createState() => _R2WBottomNavState();
}

class _R2WBottomNavState extends State<R2WBottomNav> {
  final AuthRepository _authRepository = AuthRepository();
  AppRole _role = AppRole.unknown;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = _itemsFor(_role);
    final currentPath = GoRouterState.of(context).uri.path;
    final fallbackIndex = widget.selectedIndex.clamp(0, items.length - 1);
    final selected = _indexForPath(currentPath, items) ?? fallbackIndex;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(B2BRadius.xl),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: isDark ? null : B2BShadows.elevated,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(B2BRadius.xl),
          child: NavigationBar(
            selectedIndex: selected,
            backgroundColor: Colors.transparent,
            onDestinationSelected: (index) {
              final item = items[index];
              if (item.opensWorkspace) {
                showR2WWorkspaceMenu(context, _role);
                return;
              }
              if (index == selected) return;
              if (_keepsBackHistory(item.route)) {
                context.push(item.route);
              } else {
                context.go(item.route);
              }
            },
            destinations: [
              for (final item in items)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showR2WWorkspaceMenu(BuildContext context, AppRole role) async {
  final items = _workspaceItemsFor(role);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .78,
          minChildSize: .45,
          maxChildSize: .94,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            children: [
              Text(
                role == AppRole.dealer
                    ? 'Dealer Workspace'
                    : role == AppRole.reseller
                        ? 'Reseller Workspace'
                        : role == AppRole.admin
                            ? 'Admin Workspace'
                            : 'Workspace',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Web panel navigation is available here so mobile does not hide partner features.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final group in _groupWorkspaceItems(items)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Text(
                    group.$1.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                for (final item in group.$2)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        item.icon,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: item.description.isEmpty
                        ? null
                        : Text(item.description),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push(item.route);
                    },
                  ),
              ],
              if (role == AppRole.admin) ...[
                const SizedBox(height: 12),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.errorContainer,
                    child: Icon(
                      Icons.logout_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Log out',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text('End the admin session on this device'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _confirmAndLogout(context);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _confirmAndLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text(
        'Your secure admin session will be removed from this device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await AuthRepository().signOut();
  if (context.mounted) context.go('/login');
}

bool _keepsBackHistory(String route) =>
    route == '/reports' ||
    route == '/operations' ||
    route == '/pricing/rules';

List<_NavItem> _itemsFor(AppRole role) {
  if (role == AppRole.client || role == AppRole.publicUser) {
    return const [
      _NavItem('/dashboard', 'Home', Icons.home_outlined, Icons.home_rounded),
      _NavItem('/esims', 'eSIMs', Icons.sim_card_outlined, Icons.sim_card_rounded),
      _NavItem('/orders', 'Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
      _NavItem('/reports', 'Reports', Icons.analytics_outlined, Icons.analytics_rounded),
      _NavItem('/profile', 'Menu', Icons.grid_view_outlined, Icons.grid_view_rounded, opensWorkspace: true),
    ];
  }
  if (role == AppRole.admin) {
    return const [
      _NavItem('/dashboard', 'Home', Icons.home_outlined, Icons.home_rounded),
      _NavItem('/orders', 'Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
      _NavItem('/operations', 'Ops', Icons.monitor_heart_outlined, Icons.monitor_heart_rounded),
      _NavItem('/reports', 'Reports', Icons.analytics_outlined, Icons.analytics_rounded),
      _NavItem('/profile', 'Menu', Icons.grid_view_outlined, Icons.grid_view_rounded, opensWorkspace: true),
    ];
  }
  return const [
    _NavItem('/dashboard', 'Home', Icons.home_outlined, Icons.home_rounded),
    _NavItem('/packages', 'Catalog', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
    _NavItem('/orders', 'Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    _NavItem('/customers', 'Clients', Icons.groups_outlined, Icons.groups_rounded),
    _NavItem('/profile', 'Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];
}

List<_WorkspaceItem> _workspaceItemsFor(AppRole role) {
  if (role == AppRole.reseller) {
    return const [
      _WorkspaceItem('Clients', '/customers', Icons.groups_outlined, 'Client management'),
      _WorkspaceItem('Dealers', '/dealers', Icons.people_alt_outlined, 'Dealer management'),
      _WorkspaceItem('My SIMs & eSIMs', '/esims', Icons.sim_card_outlined, 'SIM & eSIM inventory'),
      _WorkspaceItem('SIM Converter', '/sim-converter', Icons.swap_horiz_rounded, 'SIM conversion tools'),
      _WorkspaceItem('Finance Ledger', '/finance', Icons.account_balance_wallet_outlined, 'Balance, requests and wallet movements'),
      _WorkspaceItem('Dealer Wallet', '/wallet', Icons.wallet_outlined, 'Dealer wallet funding'),
      _WorkspaceItem('Dealer Pricing', '/dealers/pricing', Icons.percent_rounded, 'Dealer pricing'),
      _WorkspaceItem('Central Pricing Rules', '/pricing/rules', Icons.rule_folder_outlined, 'Central pricing and markup rules'),
      _WorkspaceItem('Operations', '/operations', Icons.dns_outlined, 'Operations center'),
      _WorkspaceItem('Notifications', '/notifications', Icons.notifications_none_rounded, 'Notification center'),
      _WorkspaceItem('Reports', '/reports', Icons.analytics_outlined, 'Reports & analytics'),
      _WorkspaceItem('Profile', '/profile', Icons.person_outline_rounded, 'Profile and workspace preferences'),
    ];
  }
  if (role == AppRole.dealer) {
    return const [
      _WorkspaceItem('Dashboard', '/dashboard', Icons.dashboard_outlined, 'Dealer dashboard'),
      _WorkspaceItem('Catalog', '/packages', Icons.layers_outlined, 'SIM & eSIM catalog'),
      _WorkspaceItem('Customer Pricing', '/pricing/customer', Icons.percent_rounded, 'Customer pricing rules'),
      _WorkspaceItem('Central Pricing Rules', '/pricing/rules', Icons.rule_folder_outlined, 'Your scoped pricing rules'),
      _WorkspaceItem('SIM Converter', '/sim-converter', Icons.swap_horiz_rounded, 'SIM conversion tools'),
      _WorkspaceItem('Finance Ledger', '/finance', Icons.account_balance_wallet_outlined, 'Balance, requests and wallet movements'),
      _WorkspaceItem('My SIMs & eSIMs', '/esims', Icons.sim_card_outlined, 'SIM & eSIM inventory'),
      _WorkspaceItem('Orders', '/orders', Icons.receipt_long_outlined, 'Dealer orders'),
      _WorkspaceItem('Clients', '/customers', Icons.groups_outlined, 'Dealer clients'),
      _WorkspaceItem('Reports', '/reports', Icons.analytics_outlined, 'Reports & analytics'),
      _WorkspaceItem('Profile', '/profile', Icons.person_outline_rounded, 'Dealer profile'),
      _WorkspaceItem('Settings', '/settings', Icons.settings_outlined, 'Dealer settings'),
    ];
  }
  if (role == AppRole.admin) {
    return const [
      _WorkspaceItem('Dashboard', '/dashboard', Icons.dashboard_outlined, 'Admin dashboard'),
      _WorkspaceItem('Customers & Orders', '/customers', Icons.shopping_cart_outlined, 'Customers and orders'),
      _WorkspaceItem('Transactions', '/finance', Icons.credit_card_outlined, 'Payments and billing'),
      _WorkspaceItem('Balance Top-ups', '/wallet', Icons.add_card_rounded, 'Balance top-up management'),
      _WorkspaceItem('Statements', '/finance', Icons.description_outlined, 'Admin statements'),
      _WorkspaceItem('Credit Management', '/wallet', Icons.account_balance_wallet_outlined, 'Credit management'),
      _WorkspaceItem('Resellers', '/admin/resellers', Icons.person_add_alt_1_outlined, 'Reseller management'),
      _WorkspaceItem('Analytics', '/reports', Icons.trending_up_rounded, 'Reports and analytics'),
      _WorkspaceItem('Unified Catalog', '/packages', Icons.layers_outlined, 'Unified provider catalog'),
      _WorkspaceItem('Catalog Gov', '/admin/governance', Icons.map_outlined, 'Catalog governance'),
      _WorkspaceItem('Smart Routing', '/admin/routing', Icons.alt_route_rounded, 'Smart routing'),
      _WorkspaceItem('Provider Markups', '/admin/commercial', Icons.percent_rounded, 'Provider markups'),
      _WorkspaceItem('Central Pricing Rules', '/pricing/rules', Icons.rule_folder_outlined, 'Central pricing and markup rules'),
      _WorkspaceItem('Profitability', '/finance', Icons.attach_money_rounded, 'Provider profitability'),
      _WorkspaceItem('Provider Ops', '/operations', Icons.dns_outlined, 'Provider operations'),
      _WorkspaceItem('Manual Fulfilment', '/admin/manual-fulfillment', Icons.assignment_outlined, 'Manual products and delivery queue'),
      _WorkspaceItem('Operations', '/operations', Icons.security_rounded, 'Admin operations center'),
      _WorkspaceItem('API Logs', '/operations', Icons.description_outlined, 'API and webhook logs'),
      _WorkspaceItem('Failed Orders', '/orders', Icons.warning_amber_rounded, 'Failed orders queue'),
      _WorkspaceItem('Audit & Access', '/admin/governance', Icons.key_outlined, 'Audit and permissions'),
      _WorkspaceItem('Notifications', '/notifications', Icons.notifications_none_rounded, 'Admin notification center'),
      _WorkspaceItem('Alert Rules', '/notifications/rules', Icons.rule_rounded, 'Notification rules'),
      _WorkspaceItem('WhatsApp', '/admin/whatsapp', Icons.chat_outlined, 'WhatsApp management'),
      _WorkspaceItem('Settings', '/settings', Icons.settings_outlined, 'Settings'),
    ];
  }
  return const [
    _WorkspaceItem('Profile', '/profile', Icons.person_outline_rounded, 'Profile and account settings'),
    _WorkspaceItem('Settings', '/settings', Icons.settings_outlined, 'Application settings'),
    _WorkspaceItem('Notifications', '/notifications', Icons.notifications_none_rounded, 'Notifications'),
    _WorkspaceItem('Support', '/support', Icons.support_agent_outlined, 'Support'),
  ];
}

List<(String, List<_WorkspaceItem>)> _groupWorkspaceItems(
  List<_WorkspaceItem> items,
) {
  final groups = <String, List<_WorkspaceItem>>{};
  for (final item in items) {
    final group = switch (item.label) {
      'Dashboard' => 'Overview',
      'Catalog' ||
      'Catalog Controls' ||
      'Unified Catalog' ||
      'Catalog Gov' ||
      'Coverage' => 'Catalog',
      'Clients' ||
      'Dealers' ||
      'Resellers' ||
      'Customers & Orders' ||
      'Dealer Performance' => 'Partners',
      'Finance Ledger' ||
      'Dealer Wallet' ||
      'Dealer Pricing' ||
      'Customer Pricing' ||
      'Central Pricing Rules' ||
      'Transactions' ||
      'Balance Top-ups' ||
      'Statements' ||
      'Credit Management' ||
      'Profitability' => 'Finance',
      'My SIMs & eSIMs' || 'SIM Converter' => 'eSIM & SIM',
      'Operations' ||
      'Provider Ops' ||
      'Failed Orders' ||
      'API Logs' ||
      'Manual Fulfilment' ||
      'Audit Log' ||
      'Audit & Access' => 'Operations',
      'Notifications' || 'Alert Rules' || 'WhatsApp' => 'Communication',
      'Reports' || 'Analytics' => 'Reports',
      _ => 'Account',
    };
    groups.putIfAbsent(group, () => []).add(item);
  }
  return groups.entries
      .map((entry) => (entry.key, entry.value))
      .toList(growable: false);
}

int? _indexForPath(String path, List<_NavItem> items) {
  for (var index = 0; index < items.length; index++) {
    final route = items[index].route;
    if (path == route || path.startsWith('$route/')) return index;
  }
  return null;
}

class _NavItem {
  const _NavItem(
    this.route,
    this.label,
    this.icon,
    this.selectedIcon, {
    this.opensWorkspace = false,
  });
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool opensWorkspace;
}

class _WorkspaceItem {
  const _WorkspaceItem(this.label, this.route, this.icon, this.description);
  final String label;
  final String route;
  final IconData icon;
  final String description;
}
