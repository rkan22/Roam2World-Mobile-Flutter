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
import 'widgets/dashboard_adaptive_sections.dart';

class ResellerDashboardScreen extends StatefulWidget {
  const ResellerDashboardScreen({super.key, this.repository});

  final DashboardRepository? repository;

  @override
  State<ResellerDashboardScreen> createState() =>
      _ResellerDashboardScreenState();
}

class _ResellerDashboardScreenState extends State<ResellerDashboardScreen> {
  static const _periods = <(String, String)>[
    ('today', 'Today'),
    ('7d', '7D'),
    ('30d', '30D'),
    ('month', 'Month'),
    ('all', 'All'),
  ];

  late final DashboardRepository _repository;
  DashboardData? _data;
  Object? _error;
  bool _loading = true;
  bool _showingStaleData = false;
  String _period = '30d';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DashboardRepository();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _loading = _data == null;
        _error = null;
      });
    }

    try {
      final result = await _repository.fetchDashboard(
        forceRefresh: forceRefresh,
        period: _period,
      );
      if (!mounted) return;
      setState(() {
        _data = result;
        _showingStaleData = _repository.lastFetchUsedStale;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPeriod(String period) async {
    if (_period == period) return;
    setState(() => _period = period);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 0),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const ContentLoadingState(label: 'Loading reseller workspace...');
    }

    if (_error != null && _data == null) {
      return ContentErrorState(
        message: _error is ApiException
            ? (_error! as ApiException).message
            : 'Dashboard could not be loaded.',
        onRetry: () => _load(forceRefresh: true),
      );
    }

    final data = _data!;
    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          B2BSpacing.lg,
          B2BSpacing.md,
          B2BSpacing.lg,
          B2BSpacing.xxxl,
        ),
        children: [
          if (_showingStaleData) ...[
            const _StaleDataBanner(),
            const SizedBox(height: B2BSpacing.md),
          ],
          _Header(
            role: data.role,
            onNotificationsTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: B2BSpacing.lg),
          _PeriodSelector(
            periods: _periods,
            selected: _period,
            loading: _loading,
            onSelected: _selectPeriod,
          ),
          const SizedBox(height: B2BSpacing.lg),
          _WalletHero(data: data),
          const SizedBox(height: B2BSpacing.lg),
          _CoreMetrics(data: data),
          if (_hasBusinessMetrics(data)) ...[
            const SizedBox(height: B2BSpacing.xl),
            _BusinessMetrics(data: data),
          ],
          const SizedBox(height: B2BSpacing.xl),
          const _SectionTitle('Quick actions'),
          const SizedBox(height: B2BSpacing.md),
          const _QuickActions(),
          const SizedBox(height: B2BSpacing.xl),
          _SectionTitle(
            'Recent orders',
            actionLabel: 'View all',
            onAction: () => context.go('/orders'),
          ),
          const SizedBox(height: B2BSpacing.md),
          _RecentOrders(orders: data.recentOrders, currency: data.currency),
        ],
      ),
    );
  }

  bool _hasBusinessMetrics(DashboardData data) =>
      data.revenue != null ||
      data.grossProfit != null ||
      data.grossMarginPercent != null ||
      data.successfulOrders != null ||
      data.totalCustomers != null;
}

class _Header extends StatelessWidget {
  const _Header({required this.role, required this.onNotificationsTap});

  final String role;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final roleLabel = role.trim().isEmpty ? 'Reseller' : role.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Roam2World',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: B2BSpacing.xs),
              Text(
                'Business overview',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: B2BSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(B2BRadius.full),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: B2BSpacing.md,
                    vertical: B2BSpacing.xs,
                  ),
                  child: Text(
                    roleLabel.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onNotificationsTap,
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periods,
    required this.selected,
    required this.loading,
    required this.onSelected,
  });

  final List<(String, String)> periods;
  final String selected;
  final bool loading;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: B2BSpacing.sm),
        itemBuilder: (context, index) {
          final period = periods[index];
          final active = selected == period.$1;
          return ChoiceChip(
            label: Text(period.$2),
            selected: active,
            onSelected: loading ? null : (_) => onSelected(period.$1),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: active
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          );
        },
      ),
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final lowBalance = data.balance <= 20;
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
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Text(
                  'Available balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (lowBalance)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: B2BSpacing.sm,
                    vertical: B2BSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(B2BRadius.full),
                  ),
                  child: const Text(
                    'LOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          Text(
            '${data.currency} ${data.balance.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  lowBalance
                      ? 'Top up to keep orders moving'
                      : 'Wallet ready for new orders',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.push('/wallet'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 44),
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

class _CoreMetrics extends StatelessWidget {
  const _CoreMetrics({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return DashboardKpiLayout(
      children: [
        B2BMetricCard(
          label: "Today's sales",
          value: '${data.currency} ${data.todaySales.toStringAsFixed(2)}',
          icon: Icons.trending_up_rounded,
          trend: 'Live performance',
          trendPositive: true,
        ),
        B2BMetricCard(
          label: 'Monthly revenue',
          value: '${data.currency} ${data.monthlySales.toStringAsFixed(2)}',
          icon: Icons.bar_chart_rounded,
          trend: 'Current month',
          trendPositive: true,
        ),
        B2BMetricCard(
          label: 'Active eSIMs',
          value: '${data.activeEsimCount}',
          icon: Icons.sim_card_outlined,
          trend: 'Currently active',
          trendPositive: true,
          onTap: () => context.go('/esims'),
        ),
        B2BMetricCard(
          label: 'Expired eSIMs',
          value: '${data.expiredEsimCount}',
          icon: Icons.schedule_rounded,
          trend: 'Needs attention',
          trendPositive: data.expiredEsimCount == 0,
          onTap: () => context.go('/esims'),
        ),
      ],
    );
  }
}

class _BusinessMetrics extends StatelessWidget {
  const _BusinessMetrics({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final metrics = <_BusinessMetric>[];

    if (data.revenue != null) {
      metrics.add(
        _BusinessMetric(
          icon: Icons.payments_outlined,
          label: 'Period revenue',
          value: '${data.currency} ${data.revenue!.toStringAsFixed(2)}',
        ),
      );
    }
    if (data.grossProfit != null) {
      metrics.add(
        _BusinessMetric(
          icon: Icons.ssid_chart_rounded,
          label: 'Gross profit',
          value: '${data.currency} ${data.grossProfit!.toStringAsFixed(2)}',
        ),
      );
    }
    if (data.grossMarginPercent != null) {
      metrics.add(
        _BusinessMetric(
          icon: Icons.percent_rounded,
          label: 'Gross margin',
          value: '${data.grossMarginPercent!.toStringAsFixed(2)}%',
        ),
      );
    }
    if (data.successfulOrders != null) {
      metrics.add(
        _BusinessMetric(
          icon: Icons.shopping_bag_outlined,
          label: 'Successful orders',
          value: '${data.successfulOrders}',
        ),
      );
    }
    if (data.totalCustomers != null) {
      metrics.add(
        _BusinessMetric(
          icon: Icons.groups_2_outlined,
          label: 'Customers',
          value: '${data.totalCustomers}',
        ),
      );
    }

    return B2BSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business pulse',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: B2BSpacing.md),
          for (var index = 0; index < metrics.length; index++) ...[
            _BusinessMetricRow(metric: metrics[index]),
            if (index < metrics.length - 1)
              const Divider(height: B2BSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _BusinessMetric {
  const _BusinessMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _BusinessMetricRow extends StatelessWidget {
  const _BusinessMetricRow({required this.metric});

  final _BusinessMetric metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(B2BRadius.md),
          ),
          child: Icon(
            metric.icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: B2BSpacing.md),
        Expanded(
          child: Text(
            metric.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Text(
          metric.value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const actions = <(IconData, String, String)>[
      (Icons.layers_outlined, 'Catalog', '/packages'),
      (Icons.add_shopping_cart_rounded, 'New order', '/packages'),
      (Icons.groups_2_outlined, 'Customers', '/customers'),
      (Icons.sim_card_outlined, 'My eSIMs', '/esims'),
      (Icons.account_balance_wallet_outlined, 'Wallet', '/wallet'),
      (Icons.insights_outlined, 'Reports', '/reports'),
    ];

    return DashboardQuickActionsLayout(
      children: [
        for (final action in actions)
          _QuickActionTile(
            icon: action.$1,
            label: action.$2,
            onTap: () => context.go(action.$3),
          ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: B2BSpacing.xs,
        vertical: B2BSpacing.md,
      ),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(B2BRadius.md),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(height: B2BSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
    this.title, {
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
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
        icon: Icons.receipt_long_outlined,
        title: 'No recent orders',
        message: 'Your latest B2B orders will appear here.',
        actionLabel: 'Browse catalog',
        onAction: () => context.go('/packages'),
      );
    }

    return B2BSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < orders.length; index++) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: B2BSpacing.md,
                vertical: B2BSpacing.xs,
              ),
              onTap: () => context.push('/orders/detail'),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                orders[index].productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(orders[index].orderNumber),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${orders[index].totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    orders[index].status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            if (index < orders.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _StaleDataBanner extends StatelessWidget {
  const _StaleDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(B2BSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(B2BRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: .4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 19, color: AppColors.warning),
          SizedBox(width: B2BSpacing.sm),
          Expanded(
            child: Text(
              'Could not refresh. Showing the last available data.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
