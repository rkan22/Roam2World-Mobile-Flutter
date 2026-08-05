import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              _Header(onNotificationsTap: () {}),
              const SizedBox(height: 20),
              const _BalanceCard(),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Quick actions'),
              const SizedBox(height: 12),
              const _QuickActions(),
              const SizedBox(height: 24),
              const _SectionTitle(title: "Today's statistics", action: 'View all'),
              const SizedBox(height: 12),
              const _StatsGrid(),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Recent orders', action: 'View all'),
              const SizedBox(height: 12),
              const _RecentOrders(),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create new',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _QuickSheetTile(
                icon: Icons.shopping_bag_outlined,
                title: 'New order',
                onTap: () => context.go('/packages'),
              ),
              _QuickSheetTile(
                icon: Icons.search_rounded,
                title: 'Search packages',
                onTap: () => context.go('/packages'),
              ),
              const _QuickSheetTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan QR',
              ),
              const _QuickSheetTile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Add customer',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onNotificationsTap;

  const _Header({required this.onNotificationsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Merhaba,', style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 2),
              Text(
                'Erkan 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available balance', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  '\$12,450.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/wallet'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Top up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;

  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          Text(action!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.inventory_2_outlined, 'Buy package', '/packages'),
      (Icons.shopping_bag_outlined, 'Create order', '/packages'),
      (Icons.qr_code_scanner_rounded, 'Scan QR', ''),
      (Icons.groups_outlined, 'Customers', ''),
    ];

    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: items[index].$3.isEmpty ? null : () => context.go(items[index].$3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(items[index].$1, color: AppColors.primary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      items[index].$2,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (index != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Orders', value: '124', delta: '+12%', positive: true)),
            SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Revenue', value: '\$8,920', delta: '+8.2%', positive: true)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Active eSIMs', value: '248', delta: '+18%', positive: true)),
            SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Pending orders', value: '16', delta: '-4%', positive: false)),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool positive;

  const _StatCard({required this.label, required this.value, required this.delta, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                Text(
                  delta,
                  style: TextStyle(
                    color: positive ? AppColors.success : AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        children: [
          _OrderTile(flag: '🇹🇷', title: 'Orange · Turkey', amount: '\$15.00', status: 'Completed'),
          Divider(height: 1),
          _OrderTile(flag: '🇺🇸', title: 'T-Mobile · USA', amount: '\$25.00', status: 'Completed'),
          Divider(height: 1),
          _OrderTile(flag: '🇬🇧', title: 'Vodafone · UK', amount: '\$19.00', status: 'Processing'),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String flag;
  final String title;
  final String amount;
  final String status;

  const _OrderTile({required this.flag, required this.title, required this.amount, required this.status});

  @override
  Widget build(BuildContext context) {
    final completed = status == 'Completed';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: const Text('Today'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            status,
            style: TextStyle(
              color: completed ? AppColors.success : AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _QuickSheetTile({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
