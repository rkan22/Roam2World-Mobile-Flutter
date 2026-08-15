import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/routing/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'dashboard_data.dart';
import 'dashboard_repository.dart';

class PartnerBusinessDashboardScreen extends StatefulWidget {
  const PartnerBusinessDashboardScreen({
    super.key,
    required this.role,
    required this.repository,
  });

  final AppRole role;
  final DashboardRepository repository;

  @override
  State<PartnerBusinessDashboardScreen> createState() =>
      _PartnerBusinessDashboardScreenState();
}

class _PartnerBusinessDashboardScreenState
    extends State<PartnerBusinessDashboardScreen> {
  DashboardData? _data;
  Object? _error;
  bool _loading = true;
  bool _balanceVisible = true;

  bool get _isDealer => widget.role == AppRole.dealer;

  @override
  void initState() {
    super.initState();
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
      final data = await widget.repository.fetchDashboard(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => _data = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const ContentLoadingState(label: 'Loading your dashboard...');
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
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          _header(),
          const SizedBox(height: 16),
          _operationsCard(data),
          const SizedBox(height: 14),
          _kpiGrid(data),
          const SizedBox(height: 14),
          _actionCenter(),
          const SizedBox(height: 14),
          _recentOrders(data),
          if (!_isDealer) ...[
            const SizedBox(height: 14),
            _resellerManagement(),
          ],
        ],
      ),
    );
  }

  Widget _header() {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SquareIconButton(
          icon: Icons.menu_rounded,
          onTap: () => showR2WWorkspaceMenu(context, widget.role),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isDealer ? 'Dealer Operations' : 'Reseller Operations',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.45,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isDealer
                    ? 'Sales, wallet, customers and active eSIM activity.'
                    : 'Sales, dealer network, wallet and eSIM operations.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _SquareIconButton(
          icon: Icons.refresh_rounded,
          onTap: () => _load(forceRefresh: true),
        ),
        const SizedBox(width: 8),
        _SquareIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () => context.push('/notifications'),
        ),
      ],
    );
  }

  Widget _operationsCard(DashboardData data) {
    final currency = data.currency.trim().isEmpty
        ? 'USD'
        : data.currency.trim().toUpperCase();
    final balance = _balanceVisible
        ? _money(data.balance, currency)
        : '••••••••';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22020817),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _isDealer
                      ? Icons.point_of_sale_outlined
                      : Icons.hub_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isDealer ? 'Sales workspace' : 'Partner workspace',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isDealer
                          ? 'Wallet ready for customer sales'
                          : 'Manage sales and your dealer network',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    setState(() => _balanceVisible = !_balanceVisible),
                icon: Icon(
                  _balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Available balance',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            balance,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1,
              letterSpacing: -.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _DarkMetric(
                  label: 'Today sales',
                  value: _money(data.todaySales, currency),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DarkMetric(
                  label: 'Active eSIMs',
                  value: '${data.activeEsimCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiGrid(DashboardData data) {
    final items = [
      _MetricData(
        'Total Sales',
        _money(data.monthlySales, data.currency),
        Icons.trending_up_rounded,
        AppColors.primary,
        AppColors.primarySoft,
      ),
      _MetricData(
        'Active eSIMs',
        '${data.activeEsimCount}',
        Icons.sim_card_outlined,
        AppColors.success,
        AppColors.successSoft,
      ),
      _MetricData(
        'Total eSIMs',
        '${data.totalEsimCount}',
        Icons.inventory_2_outlined,
        AppColors.violet,
        const Color(0xFFF3EEFF),
      ),
      _MetricData(
        'Expired',
        '${data.expiredEsimCount}',
        Icons.schedule_outlined,
        AppColors.warning,
        AppColors.warningSoft,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(width: width, child: _metricCard(item)),
          ],
        );
      },
    );
  }

  Widget _metricCard(_MetricData metric) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: B2BShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: metric.soft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(metric.icon, size: 18, color: metric.color),
          ),
          const SizedBox(height: 13),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCenter() {
    final actions = _isDealer
        ? <_ActionData>[
            _ActionData('Buy package', 'Open catalog', Icons.public_rounded,
                () => context.go('/packages')),
            _ActionData('Query GB', 'Check live usage', Icons.data_usage_rounded,
                () => context.push('/provider-tools/usage')),
            _ActionData('Renew / Top-up', 'Continue active plans',
                Icons.autorenew_rounded,
                () => context.push('/provider-tools/renew')),
            _ActionData('Clients', 'Manage customers', Icons.groups_outlined,
                () => context.go('/customers')),
            _ActionData('Request balance', 'Open finance ledger',
                Icons.add_card_rounded, () => context.push('/finance')),
            _ActionData('Orders', 'Track provisioning',
                Icons.receipt_long_outlined, () => context.go('/orders')),
          ]
        : <_ActionData>[
            _ActionData('Dealers', 'Manage dealer network',
                Icons.people_alt_outlined, () => context.push('/dealers')),
            _ActionData('Dealer Wallet', 'Funding requests',
                Icons.wallet_outlined, () => context.push('/wallet')),
            _ActionData('Dealer Pricing', 'Pricing controls',
                Icons.percent_rounded, () => context.push('/dealers/pricing')),
            _ActionData('Clients', 'Manage customers', Icons.groups_outlined,
                () => context.go('/customers')),
            _ActionData('Query GB', 'Check live usage', Icons.data_usage_rounded,
                () => context.push('/provider-tools/usage')),
            _ActionData('Renew / Top-up', 'Continue active plans',
                Icons.autorenew_rounded,
                () => context.push('/provider-tools/renew')),
          ];

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
            'Action Center',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isDealer
                ? 'Frequent dealer workflows'
                : 'Frequent reseller workflows',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < actions.length; i++) ...[
            _actionRow(actions[i]),
            if (i != actions.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _actionRow(_ActionData action) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _recentOrders(DashboardData data) {
    final theme = Theme.of(context);
    final orders = data.recentOrders.take(5).toList(growable: false);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: B2BShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 7),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Orders',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Latest tenant-scoped order activity',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Text(
                'Latest eSIM orders will appear here.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            for (var i = 0; i < orders.length; i++) ...[
              _orderRow(orders[i], data.currency),
              if (i != orders.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1),
                ),
            ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _orderRow(DashboardOrderSummary order, String currency) {
    final theme = Theme.of(context);
    final status = order.status.toLowerCase();
    final success = status.contains('complete') ||
        status.contains('success') ||
        status.contains('active');
    final failed = status.contains('fail') ||
        status.contains('cancel') ||
        status.contains('refund');
    final tone = success
        ? AppColors.success
        : failed
            ? AppColors.danger
            : AppColors.warning;
    final date = order.createdAt == null
        ? order.orderNumber
        : DateFormat('MMM d, HH:mm').format(order.createdAt!.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 17,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(order.totalAmount, currency),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.status.replaceAll('_', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tone,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resellerManagement() {
    final theme = Theme.of(context);
    final items = <_ActionData>[
      _ActionData('Central Pricing', 'Markup and pricing rules',
          Icons.rule_folder_outlined, () => context.push('/pricing/rules')),
      _ActionData('Operations', 'Provider and order operations',
          Icons.monitor_heart_outlined, () => context.push('/operations')),
      _ActionData('Reports', 'Sales and analytics', Icons.analytics_outlined,
          () => context.push('/reports')),
      _ActionData('Finance Ledger', 'Balance and wallet movements',
          Icons.account_balance_wallet_outlined, () => context.push('/finance')),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
            'Management',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            _actionRow(items[i]),
            if (i != items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  String _money(double value, String currency) {
    final normalized = currency.trim().toUpperCase();
    final symbol = switch (normalized) {
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      'TRY' => '₺',
      _ => '$normalized ',
    };
    return '$symbol${NumberFormat('#,##0.00', 'en_US').format(value)}';
  }
}

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      );
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color, this.soft);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color soft;
}

class _ActionData {
  const _ActionData(this.title, this.subtitle, this.icon, this.onTap);

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}
