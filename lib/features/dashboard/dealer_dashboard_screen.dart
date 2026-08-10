import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'dashboard_data.dart';
import 'dashboard_repository.dart';

class DealerDashboardScreen extends StatefulWidget {
  const DealerDashboardScreen({super.key, this.repository});

  final DashboardRepository? repository;

  @override
  State<DealerDashboardScreen> createState() => _DealerDashboardScreenState();
}

class _DealerDashboardScreenState extends State<DealerDashboardScreen> {
  static const _periods = <(String, String)>[
    ('today', 'Today'),
    ('7d', '7D'),
    ('30d', '30D'),
    ('month', 'Month'),
    ('all', 'All'),
  ];

  late final DashboardRepository _repository;
  DashboardData? _data;
  bool _loading = true;
  String? _error;
  String _period = '30d';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DashboardRepository();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final result = await _repository.fetchDashboard(
        period: _period,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _data = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Dealer dashboard could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 0),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading && _data == null) {
      return const ContentLoadingState(label: 'Loading dealer workspace...');
    }
    if (_error != null && _data == null) {
      return ContentErrorState(message: _error!, onRetry: () => _load(forceRefresh: true));
    }

    final data = _data!;
    final lowBalance = data.balance <= 5;
    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.md, B2BSpacing.lg, B2BSpacing.xxxl),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEALER OPERATIONS', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: .7)),
                    const SizedBox(height: B2BSpacing.xs),
                    Text('Sales dashboard', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: B2BSpacing.xs),
                    const Text('Wallet, revenue, customers and eSIM activity.', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton.filledTonal(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_none_rounded)),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _periods.length,
              separatorBuilder: (_, _) => const SizedBox(width: B2BSpacing.xs),
              itemBuilder: (context, index) {
                final item = _periods[index];
                return ChoiceChip(
                  label: Text(item.$2),
                  selected: _period == item.$1,
                  onSelected: _loading ? null : (_) {
                    setState(() => _period = item.$1);
                    _load();
                  },
                );
              },
            ),
          ),
          if (lowBalance) ...[
            const SizedBox(height: B2BSpacing.lg),
            B2BSurface(
              backgroundColor: AppColors.warning.withValues(alpha: .08),
              borderColor: AppColors.warning.withValues(alpha: .28),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: Text('Low wallet balance: ${data.currency} ${data.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800))),
                TextButton(onPressed: () => context.push('/wallet'), child: const Text('Request')),
              ]),
            ),
          ],
          const SizedBox(height: B2BSpacing.lg),
          Row(children: [
            Expanded(child: B2BMetricCard(label: 'Balance', value: '${data.currency} ${data.balance.toStringAsFixed(2)}', icon: Icons.account_balance_wallet_outlined)),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(child: B2BMetricCard(label: 'Active eSIMs', value: '${data.activeEsimCount}', icon: Icons.sim_card_outlined)),
          ]),
          const SizedBox(height: B2BSpacing.sm),
          Row(children: [
            Expanded(child: B2BMetricCard(label: 'Revenue', value: data.revenue == null ? '—' : '${data.currency} ${data.revenue!.toStringAsFixed(2)}', icon: Icons.trending_up_rounded)),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(child: B2BMetricCard(label: 'Customers', value: data.totalCustomers?.toString() ?? '—', icon: Icons.groups_outlined)),
          ]),
          if (data.grossProfit != null || data.grossMarginPercent != null) ...[
            const SizedBox(height: B2BSpacing.sm),
            B2BSurface(
              child: Row(children: [
                Expanded(child: _MiniMetric(label: 'Gross profit', value: data.grossProfit == null ? '—' : '${data.currency} ${data.grossProfit!.toStringAsFixed(2)}')),
                Expanded(child: _MiniMetric(label: 'Margin', value: data.grossMarginPercent == null ? '—' : '${data.grossMarginPercent!.toStringAsFixed(1)}%')),
                Expanded(child: _MiniMetric(label: 'Successful', value: data.successfulOrders?.toString() ?? '—')),
              ]),
            ),
          ],
          const SizedBox(height: B2BSpacing.xl),
          Text('Action center', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: B2BSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: B2BSpacing.sm,
            mainAxisSpacing: B2BSpacing.sm,
            childAspectRatio: 1.55,
            children: [
              _Action(title: 'Buy package', subtitle: 'Operator catalog', icon: Icons.public_rounded, onTap: () => context.go('/packages')),
              _Action(title: 'Clients', subtitle: 'Customer base', icon: Icons.groups_outlined, onTap: () => context.go('/clients')),
              _Action(title: 'Orders', subtitle: 'Provisioning', icon: Icons.receipt_long_outlined, onTap: () => context.go('/orders')),
              _Action(title: 'My eSIMs', subtitle: 'Inventory & usage', icon: Icons.sim_card_outlined, onTap: () => context.push('/esims')),
              _Action(title: 'Request balance', subtitle: 'Wallet & ledger', icon: Icons.add_card_rounded, onTap: () => context.push('/wallet')),
              _Action(title: 'Reports', subtitle: 'Sales intelligence', icon: Icons.analytics_outlined, onTap: () => context.push('/reports')),
            ],
          ),
          const SizedBox(height: B2BSpacing.xl),
          Row(children: [
            Expanded(child: Text('Recent orders', style: Theme.of(context).textTheme.titleLarge)),
            TextButton(onPressed: () => context.go('/orders'), child: const Text('View all')),
          ]),
          const SizedBox(height: B2BSpacing.sm),
          if (data.recentOrders.isEmpty)
            const ContentEmptyState(icon: Icons.receipt_long_outlined, title: 'No recent orders', message: 'New dealer orders will appear here.')
          else
            for (final order in data.recentOrders.take(5)) ...[
              B2BSurface(
                child: Row(children: [
                  const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (order.orderNumber.isNotEmpty) Text(order.orderNumber, style: const TextStyle(color: AppColors.textSecondary)),
                  ])),
                  const SizedBox(width: B2BSpacing.sm),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${data.currency} ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(order.status, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                ]),
              ),
              const SizedBox(height: B2BSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
      ]);
}

class _Action extends StatelessWidget {
  const _Action({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => B2BSurface(
        onTap: onTap,
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(B2BRadius.sm)), child: Icon(icon, color: AppColors.primary, size: 21)),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
        ]),
      );
}
