import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == selectedIndex) return;
        context.go(_routes[index]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: 'Packages',
        ),
        NavigationDestination(
          icon: Icon(Icons.sim_card_outlined),
          selectedIcon: Icon(Icons.sim_card_rounded),
          label: 'eSIMs',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag_rounded),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
