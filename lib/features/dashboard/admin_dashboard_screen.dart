import 'package:flutter/material.dart';

import '../../shared/widgets/animated_metric_value.dart';
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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.repository});

  final DashboardRepository? repository;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final DashboardRepository _repository;
  DashboardData? _data;
  bool _loading = true;
  bool _refreshing = false;
  bool _stale = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DashboardRepository(role: AppRole.admin);
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
      final data = await _repository.fetchDashboard(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _data = data;
        _stale = _repository.lastFetchUsedStale;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Admin dashboard could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _repository.invalidateCache();
    try {
      await _load(forceRefresh: true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 0),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
            children: [
              _header(),
              if (_stale) ...[const SizedBox(height: 12), const _StaleBanner()],
              const SizedBox(height: 14),
              if (_loading && _data == null)
                const ContentLoadingState(
                  label: 'Loading admin control center...',
                )
              else if (_error != null && _data == null)
                ContentErrorState(message: _error!, onRetry: _refresh)
              else if (_data != null)
                _content(_data!),
            ],
          ),
        ),
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
          onTap: () => showR2WWorkspaceMenu(context, AppRole.admin),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.45,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Platform revenue, partners, orders and wallet operations.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
          onTap: _refresh,
          loading: _refreshing,
        ),
        const SizedBox(width: 8),
        _SquareIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () => context.push('/notifications'),
        ),
      ],
    );
  }

  Widget _content(DashboardData data) {
    final currency = data.currency.trim().isEmpty
        ? 'USD'
        : data.currency.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _controlCenter(data, currency),
        const SizedBox(height: 14),
        _kpiGrid(data, currency),
        const SizedBox(height: 14),
        _operationsStatus(data),
        const SizedBox(height: 14),
        _platformSnapshot(data),
        const SizedBox(height: 14),
        _adminTools(),
        const SizedBox(height: 14),
        _recentOrders(data, currency),
      ],
    );
  }

  Widget _controlCenter(DashboardData data, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22020817),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -34,
            child: IgnorePointer(
              child: Icon(
                Icons.admin_panel_settings_outlined,
                size: 170,
                color: Colors.white.withValues(alpha: .055),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Control Center',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Live platform overview',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: AppColors.success),
                        SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Total revenue',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedMetricValue(
                value: _money(data.monthlySales, currency),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1,
                  letterSpacing: -.9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroMetric(label: 'Orders', value: '${data.totalOrders}'),
                  _HeroMetric(
                    label: 'Resellers',
                    value: '${data.resellerCount}',
                  ),
                  _HeroMetric(label: 'Dealers', value: '${data.dealerCount}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiGrid(DashboardData data, String currency) {
    final items = <_MetricData>[
      _MetricData(
        'Total Revenue',
        _money(data.monthlySales, currency),
        Icons.trending_up_rounded,
        AppColors.primary,
        AppColors.primarySoft,
      ),
      _MetricData(
        'Total Orders',
        '${data.totalOrders}',
        Icons.receipt_long_outlined,
        AppColors.violet,
        const Color(0xFFF3EEFF),
      ),
      _MetricData(
        'Resellers',
        '${data.resellerCount}',
        Icons.hub_outlined,
        AppColors.success,
        AppColors.successSoft,
      ),
      _MetricData(
        'Dealers',
        '${data.dealerCount}',
        Icons.groups_outlined,
        AppColors.orange,
        const Color(0xFFFFF2E8),
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
          AnimatedMetricValue(
            value: metric.value,
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _operationsStatus(DashboardData data) {
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
            'Operations Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Live order and wallet request counts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/orders'),
                  child: _StatusBlock(
                    label: 'Pending',
                    value: '${data.pendingOrders}',
                    icon: Icons.schedule_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/orders'),
                  child: _StatusBlock(
                    label: 'Done',
                    value: '${data.completedOrders}',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/orders'),
                  child: _StatusBlock(
                    label: 'Failed',
                    value: '${data.failedOrders}',
                    icon: Icons.error_outline_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/finance'),
                  child: _StatusBlock(
                    label: 'Wallet',
                    value: '${data.pendingWalletRequests}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/admin/manual-fulfillment'),
                  child: _StatusBlock(
                    label: 'Manual',
                    value: '${data.manualFulfillmentPending}',
                    icon: Icons.assignment_outlined,
                    color: AppColors.violet,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _platformSnapshot(DashboardData data) {
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
            'Platform Snapshot',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Items requiring operational attention',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/admin/provider-retry'),
                  child: _StatusBlock(
                    label: 'Provider Review',
                    value: '${data.providerRetriesRequiringReview}',
                    icon: Icons.sync_problem_outlined,
                    color: AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/support'),
                  child: _StatusBlock(
                    label: 'Open Support',
                    value: '${data.supportTicketsOpen}',
                    icon: Icons.support_agent_outlined,
                    color: AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/admin/manual-fulfillment'),
                  child: _StatusBlock(
                    label: 'Blank SIMs',
                    value: '${data.availableBlankSims}',
                    icon: Icons.sim_card_outlined,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminTools() {
    final theme = Theme.of(context);
    final tools = <_ToolData>[
      _ToolData(
        'Operations',
        'Provider & order ops',
        Icons.dns_outlined,
        '/operations',
      ),
      _ToolData(
        'Reports',
        'Sales & analytics',
        Icons.analytics_outlined,
        '/reports',
      ),
      _ToolData(
        'Finance',
        'Ledger & wallet',
        Icons.account_balance_wallet_outlined,
        '/finance',
      ),
      _ToolData(
        'Resellers',
        'Partner management',
        Icons.hub_outlined,
        '/admin/resellers',
      ),
      _ToolData(
        'Dealers',
        'Dealer management',
        Icons.groups_outlined,
        '/admin/dealers',
      ),
      _ToolData(
        'Pricing',
        'Central pricing rules',
        Icons.price_change_outlined,
        '/pricing/rules',
      ),
      _ToolData(
        'Provider Health',
        'Provider availability',
        Icons.monitor_heart_outlined,
        '/admin/provider-health',
      ),
      _ToolData(
        'Retry Queue',
        'Failed provider jobs',
        Icons.replay_circle_filled_outlined,
        '/admin/provider-retry',
      ),
      _ToolData(
        'Callbacks',
        'Provider callback logs',
        Icons.webhook_outlined,
        '/admin/provider-callbacks',
      ),
      _ToolData(
        'Routing',
        'Provider routing rules',
        Icons.alt_route_outlined,
        '/admin/routing',
      ),
      _ToolData(
        'Manual Fulfillment',
        'Manual order tasks',
        Icons.assignment_outlined,
        '/admin/manual-fulfillment',
      ),
      _ToolData(
        'Governance',
        'Audit and controls',
        Icons.policy_outlined,
        '/admin/governance',
      ),
      _ToolData(
        'WhatsApp',
        'Messaging operations',
        Icons.chat_outlined,
        '/admin/whatsapp',
      ),
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
            'Admin Tools',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Platform controls and partner operations',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tool in tools)
                    SizedBox(width: width, child: _toolCard(tool)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _toolCard(_ToolData tool) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(tool.route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tool.icon, size: 18, color: AppColors.primary),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tool.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentOrders(DashboardData data, String currency) {
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
                        '${data.totalOrders} platform orders',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/orders'),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Text('Latest platform orders will appear here.'),
            )
          else
            for (var i = 0; i < orders.length; i++) ...[
              _orderRow(orders[i], currency),
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
    final status = order.status.trim().isEmpty ? 'processing' : order.status;
    final date = order.createdAt == null
        ? order.orderNumber
        : DateFormat('MMM d, HH:mm').format(order.createdAt!.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/orders'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
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
                    const SizedBox(height: 3),
                    Text(
                      '$date · ${status.replaceAll('_', ' ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _money(order.totalAmount, currency),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: loading
            ? const Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    ),
  );
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 92),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warningSoft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.warning.withValues(alpha: .25)),
    ),
    child: const Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.warning),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Showing cached admin data. Pull down or tap refresh to retry.',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
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

class _ToolData {
  const _ToolData(this.title, this.subtitle, this.icon, this.route);

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
