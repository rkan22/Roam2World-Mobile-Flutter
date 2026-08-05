import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'dashboard_data.dart';
import 'dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.repository});

  final DashboardRepository? repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardRepository _repository;
  DashboardData? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DashboardRepository();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await _repository.fetchDashboard();
      if (!mounted) return;
      setState(() => _data = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/packages'),
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const ContentLoadingState(message: 'Loading your workspace...');
    }
    if (_error != null && _data == null) {
      return ContentErrorState(
        message: _error is ApiException
            ? (_error! as ApiException).message
            : 'Dashboard could not be loaded.',
        onRetry: _load,
      );
    }

    final data = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _Header(onNotificationsTap: () => context.push('/notifications')),
          const SizedBox(height: 20),
          _BalanceCard(data: data),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Quick actions'),
          const SizedBox(height: 12),
          const _QuickActions(),
          const SizedBox(height: 24),
          const _SectionTitle(title: "Today's statistics"),
          const SizedBox(height: 12),
          _StatsGrid(data: data),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Recent orders'),
          const SizedBox(height: 12),
          _RecentOrders(orders: data.recentOrders, currency: data.currency),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 2),
              Text('Roam2World', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onNotificationsTap,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.navy]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${data.role.toUpperCase()} · Available balance', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${data.currency} ${data.balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/wallet'),
                icon: const Icon(Icons.add_rounded),
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
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.inventory_2_outlined, 'Packages', '/packages'),
      (Icons.shopping_bag_outlined, 'Orders', '/orders'),
      (Icons.sim_card_outlined, 'eSIMs', '/esims'),
      (Icons.groups_outlined, 'Customers', '/customers'),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: InkWell(
              onTap: () => context.go(items[i].$3),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Icon(items[i].$1, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(items[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _StatCard(label: 'Today sales', value: '${data.currency} ${data.todaySales.toStringAsFixed(2)}')),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'Monthly sales', value: '${data.currency} ${data.monthlySales.toStringAsFixed(2)}')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(label: 'Active eSIMs', value: '${data.activeEsimCount}')),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'Expired eSIMs', value: '${data.expiredEsimCount}')),
        ]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders({required this.orders, required this.currency});
  final List<DashboardOrderSummary> orders;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return ContentEmptyState(
        title: 'No recent orders',
        message: 'Your latest mobile orders will appear here.',
        actionLabel: 'Browse packages',
        onAction: () => context.go('/packages'),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < orders.length; i++) ...[
            ListTile(
              onTap: () => context.push('/orders/detail'),
              leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
              title: Text(orders[i].productName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(orders[i].orderNumber),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$currency ${orders[i].totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(orders[i].status, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (i < orders.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
