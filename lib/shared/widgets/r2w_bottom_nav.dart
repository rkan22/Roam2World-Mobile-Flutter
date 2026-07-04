import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class R2WBottomNav extends StatelessWidget {
  final int selectedIndex;

  const R2WBottomNav({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == selectedIndex) return;

        switch (index) {
          case 0:
            context.go('/dashboard');
            break;
          case 1:
            context.go('/packages');
            break;
          case 2:
            context.go('/orders');
            break;
          case 3:
            context.go('/esims');
            break;
          case 4:
            context.go('/wallet');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront_rounded),
          label: 'Store',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.sim_card_outlined),
          selectedIcon: Icon(Icons.sim_card_rounded),
          label: 'eSIMs',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Wallet',
        ),
      ],
    );
  }
}
