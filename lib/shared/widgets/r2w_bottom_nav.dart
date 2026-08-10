import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens/b2b_tokens.dart';

class R2WBottomNav extends StatelessWidget {
  final int selectedIndex;

  const R2WBottomNav({super.key, required this.selectedIndex});

  static const _routes = [
    '/dashboard',
    '/packages',
    '/esims',
    '/orders',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            selectedIndex: selectedIndex,
            backgroundColor: Colors.transparent,
            onDestinationSelected: (index) {
              if (index == selectedIndex) return;
              context.go(_routes[index]);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag_rounded),
                label: 'Packages',
              ),
              NavigationDestination(
                icon: Icon(Icons.sim_card_outlined),
                selectedIcon: Icon(Icons.sim_card_rounded),
                label: 'eSIMs',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_rounded),
                selectedIcon: Icon(Icons.swap_horiz_rounded),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
