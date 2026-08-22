import 'package:flutter/material.dart';

import '../../shared/widgets/animated_metric_value.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/notifications/push_notification_service.dart';
import '../../core/routing/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'dashboard_data.dart';
import 'dashboard_repository.dart';
import 'dashboard_topup_sheet.dart';

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
    extends State<PartnerBusinessDashboardScreen>
    with WidgetsBindingObserver {
  DashboardData? _data;
  Object? _error;
  bool _loading = true;
  bool _refreshing = false;
  bool _balanceVisible = true;
  String _period = '30d';

  static const _periods = <(String, String)>[
    ('today', 'Today'),
    ('7d', '7 days'),
    ('30d', '30 days'),
    ('month', 'This month'),
    ('all', 'All time'),
  ];

  bool get _isDealer => widget.role == AppRole.dealer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    PushNotificationService.instance.refreshUnreadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PushNotificationService.instance.refreshUnreadCount();
    }
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
        period: _period,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshDashboard() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    widget.repository.invalidateCache();
    try {
      await _load(forceRefresh: true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _selectPeriod(String value) async {
    if (_period == value) return;
    setState(() {
      _period = value;
      _loading = true;
    });
    await _load(forceRefresh: true);
  }

  Future<void> _openTopUp(String currency) async {
    final submitted = await showDashboardTopUpSheet(
      context,
      currency: currency.trim().isEmpty ? 'USD' : currency,
    );
    if (submitted == true && mounted) {
      await _refreshDashboard();
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
        onRetry: _refreshDashboard,
      );
    }

    final data = _data!;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
          children: [
            _header(),
            const SizedBox(height: 14),
            _periodSelector(),
            if (_error != null) ...[const SizedBox(height: 12), _inlineError()],
            if (_isLowBalance(data)) ...[
              const SizedBox(height: 12),
              _lowBalanceBanner(data),
            ],
            const SizedBox(height: 14),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.45,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isDealer
                    ? 'Sales, wallet, customers and eSIM activity.'
                    : 'Sales, dealer network, margin and eSIM operations.',
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
          onTap: _refreshDashboard,
          loading: _refreshing,
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<int>(
          valueListenable: mobileNotificationUnreadCount,
          builder: (context, unreadCount, _) => _SquareIconButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: unreadCount,
            onTap: () async {
              await context.push('/notifications');
              if (mounted) {
                PushNotificationService.instance.refreshUnreadCount();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _periodSelector() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _periods[index];
          final selected = _period == item.$1;
          return ChoiceChip(
            label: Text(item.$2),
            selected: selected,
            onSelected: (_) => _selectPeriod(item.$1),
            visualDensity: VisualDensity.compact,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }

  Widget _inlineError() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.warningSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.warning.withValues(alpha: .25)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 17, color: AppColors.warning),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Could not refresh this period. Showing the last loaded data.',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  bool _isLowBalance(DashboardData data) =>
      data.balance <= (_isDealer ? 5 : 20);

  Widget _lowBalanceBanner(DashboardData data) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.warningSoft,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.warning.withValues(alpha: .3)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.account_balance_wallet_outlined,
          color: AppColors.warning,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Low balance',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                _isDealer
                    ? 'Request balance before the next customer order.'
                    : 'Add funds to keep dealer and customer orders moving.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push('/finance'),
          child: Text(_isDealer ? 'Request' : 'Open'),
        ),
      ],
    ),
  );

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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -18,
            bottom: -24,
            child: IgnorePointer(
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 150,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Column(
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
                      color: Colors.white70,
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
                              ? '${data.successfulOrders} successful orders'
                              : '${data.customerCount} customers · ${data.successfulOrders} successful orders',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              AnimatedMetricValue(
                value: balance,
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
              const SizedBox(height: 22),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => _openTopUp(currency),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Add Funds',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiGrid(DashboardData data) {
    final items = <_MetricData>[
      _MetricData(
        'Revenue',
        _money(data.monthlySales, data.currency),
        '${data.successfulOrders} successful orders',
        Icons.trending_up_rounded,
        const Color(0xFF334155),
        const Color(0xFFF1F5F9),
      ),
      _MetricData(
        'Gross Profit',
        _money(data.grossProfit, data.currency),
        '${data.grossMarginPercent.toStringAsFixed(2)}% margin',
        Icons.account_balance_outlined,
        AppColors.violet,
        const Color(0xFFF3EEFF),
      ),
      _MetricData(
        'Customers',
        '${data.customerCount}',
        '${data.totalOrders} orders in period',
        Icons.groups_outlined,
        AppColors.orange,
        const Color(0xFFFFF2E8),
      ),
      _MetricData(
        'Active eSIMs',
        '${data.activeEsimCount}',
        '${data.totalEsimCount} total inventory',
        Icons.sim_card_outlined,
        AppColors.success,
        AppColors.successSoft,
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
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCenter() {
    final actions = _isDealer
        ? <_ActionData>[
            _ActionData(
              'Buy package',
              'Open catalog',
              Icons.public_rounded,
              () => context.go('/packages'),
            ),
            _ActionData(
              'Query GB',
              'Check live usage',
              Icons.data_usage_rounded,
              () => context.push('/provider-tools/usage'),
            ),
            _ActionData(
              'Renew / Top-up',
              'Continue active plans',
              Icons.autorenew_rounded,
              () => context.push('/provider-tools/renew'),
            ),
            _ActionData(
              'Clients',
              'Manage customers',
              Icons.groups_outlined,
              () => context.go('/customers'),
            ),
            _ActionData(
              'Request balance',
              'Open finance ledger',
              Icons.add_card_rounded,
              () => context.push('/finance'),
            ),
            _ActionData(
              'Orders',
              'Track provisioning',
              Icons.receipt_long_outlined,
              () => context.go('/orders'),
            ),
          ]
        : <_ActionData>[
            _ActionData(
              'Dealers',
              'Manage dealer network',
              Icons.people_alt_outlined,
              () => context.push('/dealers'),
            ),
            _ActionData(
              'Buy eSIM',
              'Open catalog',
              Icons.sim_card_download_outlined,
              () => context.go('/packages'),
            ),
            _ActionData(
              'Dealer Pricing',
              'Pricing controls',
              Icons.percent_rounded,
              () => context.push('/dealers/pricing'),
            ),
            _ActionData(
              'Clients',
              'Manage customers',
              Icons.groups_outlined,
              () => context.go('/customers'),
            ),
            _ActionData(
              'Query GB',
              'Check live usage',
              Icons.data_usage_rounded,
              () => context.push('/provider-tools/usage'),
            ),
            _ActionData(
              'Renew / Top-up',
              'Continue active plans',
              Icons.autorenew_rounded,
              () => context.push('/provider-tools/renew'),
            ),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in actions)
                    SizedBox(width: width, child: _actionTile(action)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _actionColor(String title) {
    final value = title.toLowerCase();
    if (value.contains('buy')) return AppColors.primary;
    if (value.contains('pricing') || value.contains('renew')) {
      return AppColors.violet;
    }
    if (value.contains('client') || value.contains('customer')) {
      return AppColors.orange;
    }
    if (value.contains('query') || value.contains('usage')) {
      return AppColors.success;
    }
    if (value.contains('balance') || value.contains('finance')) {
      return AppColors.warning;
    }
    return const Color(0xFF334155);
  }

  Color _actionSoft(String title) {
    final color = _actionColor(title);
    if (color == AppColors.primary) return AppColors.primarySoft;
    if (color == AppColors.violet) return const Color(0xFFF3EEFF);
    if (color == AppColors.orange) return const Color(0xFFFFF2E8);
    if (color == AppColors.success) return AppColors.successSoft;
    if (color == AppColors.warning) return AppColors.warningSoft;
    return const Color(0xFFF1F5F9);
  }

  Widget _actionTile(_ActionData action) {
    final theme = Theme.of(context);
    final iconColor = _actionColor(action.title);
    final iconSoft = _actionSoft(action.title);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 108),
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
                      color: iconSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(action.icon, size: 18, color: iconColor),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
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
                        '${data.totalOrders} orders in ${_periodLabel(data.period)}',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Text(
                'Latest orders will appear here.',
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
    final status = order.status.trim().isEmpty ? 'processing' : order.status;
    final lower = status.toLowerCase();
    final success =
        lower.contains('complete') ||
        lower.contains('success') ||
        lower.contains('active') ||
        lower.contains('deliver');
    final failure =
        lower.contains('fail') ||
        lower.contains('cancel') ||
        lower.contains('refund');
    final statusColor = failure
        ? AppColors.danger
        : success
        ? AppColors.success
        : AppColors.warning;
    final date = order.createdAt == null
        ? order.orderNumber
        : DateFormat('MMM d, HH:mm').format(order.createdAt!.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 18,
              color: Color(0xFF334155),
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
                  '${order.orderNumber} · $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
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
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status.replaceAll('_', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9.5,
                  color: statusColor,
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
      _ActionData(
        'Operations',
        'Provider and order operations',
        Icons.dns_outlined,
        () => context.push('/operations'),
      ),
      _ActionData(
        'Reports',
        'Sales and analytics',
        Icons.analytics_outlined,
        () => context.push('/reports'),
      ),
      _ActionData(
        'Finance',
        'Ledger and wallet movements',
        Icons.account_balance_wallet_outlined,
        () => context.push('/finance'),
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
            'Management',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Finance, reports and operational controls',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++) ...[
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 6,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _actionSoft(items[i].title),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    items[i].icon,
                    size: 19,
                    color: _actionColor(items[i].title),
                  ),
                ),
                title: Text(
                  items[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  items[i].subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: items[i].onTap,
              ),
            ),
            if (i != items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  String _periodLabel(String value) {
    for (final item in _periods) {
      if (item.$1 == value) return item.$2.toLowerCase();
    }
    return value;
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
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool loading;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: loading ? null : onTap,
    borderRadius: BorderRadius.circular(13),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: loading
          ? const Center(
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.textPrimary),
                if (badgeCount > 0)
                  Positioned(
                    right: -7,
                    top: -7,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}

class _MetricData {
  const _MetricData(
    this.label,
    this.value,
    this.detail,
    this.icon,
    this.color,
    this.soft,
  );

  final String label;
  final String value;
  final String detail;
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
