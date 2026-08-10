import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_role.dart';
import '../../features/auth/auth_repository.dart';

class R2WBottomNav extends StatefulWidget {
  const R2WBottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  State<R2WBottomNav> createState() => _R2WBottomNavState();
}

class _R2WBottomNavState extends State<R2WBottomNav> {
  final _authRepository = AuthRepository();
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
    final items = _itemsFor(_role);
    final currentPath = GoRouterState.of(context).uri.path;
    final selected = _indexForPath(currentPath, items) ??
        widget.selectedIndex.clamp(0, items.length - 1);

    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) {
        if (index == selected) return;
        context.go(items[index].route);
      },
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
    );
  }
}

List<_NavItem> _itemsFor(AppRole role) {
  if (role == AppRole.client || role == AppRole.publicUser) {
    return const [
      _NavItem('/dashboard', 'Home', Icons.home_outlined, Icons.home_rounded),
      _NavItem('/esims', 'eSIMs', Icons.sim_card_outlined, Icons.sim_card_rounded),
      _NavItem('/orders', 'Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
      _NavItem('/reports', 'Reports', Icons.analytics_outlined, Icons.analytics_rounded),
      _NavItem('/profile', 'More', Icons.grid_view_outlined, Icons.grid_view_rounded),
    ];
  }

  if (role == AppRole.admin) {
    return const [
      _NavItem('/dashboard', 'Home', Icons.home_outlined, Icons.home_rounded),
      _NavItem('/orders', 'Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
      _NavItem('/operations', 'Ops', Icons.monitor_heart_outlined, Icons.monitor_heart_rounded),
      _NavItem('/reports', 'Reports', Icons.analytics_outlined, Icons.analytics_rounded),
      _NavItem('/profile', 'More', Icons.grid_view_outlined, Icons.grid_view_rounded),
    ];
  }

  return const [
    _NavItem('/dashboard', 'Home', Icons.home_outlined, Icons.home_rounded),
    _NavItem('/packages', 'Catalog', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
    _NavItem('/orders', 'Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    _NavItem('/clients', 'Clients', Icons.groups_outlined, Icons.groups_rounded),
    _NavItem('/profile', 'More', Icons.grid_view_outlined, Icons.grid_view_rounded),
  ];
}

int? _indexForPath(String path, List<_NavItem> items) {
  for (var index = 0; index < items.length; index++) {
    final route = items[index].route;
    if (path == route || path.startsWith('$route/')) return index;
  }
  if (path.startsWith('/customers')) {
    final clientIndex = items.indexWhere((item) => item.route == '/clients');
    if (clientIndex >= 0) return clientIndex;
  }
  return null;
}

class _NavItem {
  const _NavItem(this.route, this.label, this.icon, this.selectedIcon);

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
