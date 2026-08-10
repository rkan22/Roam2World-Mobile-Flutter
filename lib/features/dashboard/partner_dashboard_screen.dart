import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/routing/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'dashboard_data.dart';
import 'dashboard_repository.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key, required this.role, this.repository});

  final AppRole role;
  final DashboardRepository? repository;

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  late final DashboardRepository _repository;
  DashboardData? _data;
  bool _loading = true;
  bool _stale = false;
  String? _error;
  bool _balanceVisible = true;

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
      final data = await _repository.fetchDashboard(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _data = data;
        _stale = _repository.lastFetchUsedStale;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Partner dashboard could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isReseller => widget.role == AppRole.reseller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              B2BSpacing.lg,
              B2BSpacing.md,
              B2BSpacing.lg,
              B2BSpacing.xxl,
            ),
            children: [
              _header(),
              if (_stale) ...[
                const SizedBox(height: B2BSpacing.md),
                _staleBanner(),
              ],
              const SizedBox(height: B2BSpacing.lg),
              if (_loading && _data == null)
                const ContentLoadingState(label: 'Loading partner workspace...')
              else if (_error != null && _data == null)
                ContentErrorState(
                  message: _error!,
                  onRetry: () => _load(forceRefresh: true),
                )
              else if (_data != null)
                _content(_data!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.role.label} Workspace',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: B2BSpacing.xxs),
                Text(
                  _isReseller
                      ? 'Manage sales, dealer network and commercial controls.'
                      : 'Manage customer sales, pricing and wallet activity.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: B2BSpacing.xs),
          IconButton.filledTonal(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      );

  Widget _content(DashboardData data) {
    final currency = data.currency.trim().isEmpty ? 'USD' : data.currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(data, currency),
        const SizedBox(height: B2BSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: B2BSpacing.sm,
          mainAxisSpacing: B2BSpacing.sm,
          childAspectRatio: 1.35,
          children: [
            B2BMetricCard(
              label: 'Monthly sales',
              value: _money(data.monthlySales, currency),
              icon: Icons.trending_up_rounded,
            ),
            B2BMetricCard(
              label: 'Today sales',
              value: _money(data.todaySales, currency),
              icon: Icons.today_rounded,
            ),
            B2BMetricCard(
              label: 'Active eSIMs',
              value: '${data.activeEsimCount}',
              icon: Icons.sim_card_outlined,
            ),
            B2BMetricCard(
              label: 'Expired eSIMs',
              value: '${data.expiredEsimCount}',
              icon: Icons.timer_off_outlined,
            ),
          ],
        ),
        const SizedBox(height: B2BSpacing.xl),
        Text('Business controls', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: B2BSpacing.xs),
        Text(
          _isReseller
              ? 'Direct access to reseller finance, dealer and operations workflows.'
              : 'Direct access to dealer sales, customer pricing and finance workflows.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: B2BSpacing.md),
        _workspaceActions(),
        const SizedBox(height: B2BSpacing.xl),
        _recentOrders(data, currency),
      ],
    );
  }

  Widget _hero(DashboardData data, String currency) {
    final amount = _balanceVisible ? _money(data.balance, currency) : '••••••';
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: B2BSpacing.sm,
                  vertical: B2BSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(B2BRadius.pill),
                ),
                child: Text(
                  widget.role.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _balanceVisible = !_balanceVisible),
                icon: Icon(
                  _balanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          Text(
            _isReseller ? 'Available partner credit' : 'Available dealer balance',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: B2BSpacing.xs),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: B2BSpacing.lg),
          Wrap(
            spacing: B2BSpacing.sm,
            runSpacing: B2BSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: () => context.push('/finance'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Finance'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/packages'),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('New sale'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workspaceActions() {
    final actions = _isReseller
        ? const [
            _WorkspaceAction('Dealer Network', Icons.storefront_outlined, '/dealers'),
            _WorkspaceAction('Dealer Pricing', Icons.percent_rounded, '/dealers/pricing'),
            _WorkspaceAction('Finance Ledger', Icons.receipt_long_outlined, '/finance'),
            _WorkspaceAction('Operations', Icons.monitor_heart_outlined, '/operations'),
            _WorkspaceAction('Notification Rules', Icons.notifications_active_outlined, '/notifications/rules'),
            _WorkspaceAction('SIM Converter', Icons.sim_card_download_outlined, '/sim-converter'),
            _WorkspaceAction('Clients', Icons.groups_outlined, '/clients'),
            _WorkspaceAction('Reports', Icons.analytics_outlined, '/reports'),
          ]
        : const [
            _WorkspaceAction('Customer Pricing', Icons.percent_rounded, '/pricing/customer'),
            _WorkspaceAction('Finance Ledger', Icons.receipt_long_outlined, '/finance'),
            _WorkspaceAction('Notification Rules', Icons.notifications_active_outlined, '/notifications/rules'),
            _WorkspaceAction('SIM Converter', Icons.sim_card_download_outlined, '/sim-converter'),
            _WorkspaceAction('Clients', Icons.groups_outlined, '/clients'),
            _WorkspaceAction('Orders', Icons.shopping_bag_outlined, '/orders'),
            _WorkspaceAction('eSIMs', Icons.sim_card_outlined, '/esims'),
            _WorkspaceAction('Reports', Icons.analytics_outlined, '/reports'),
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: B2BSpacing.sm,
        mainAxisSpacing: B2BSpacing.sm,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return B2BSurface(
          onTap: () => context.push(action.route),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: Icon(action.icon, color: AppColors.primary),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        );
      },
    );
  }

  Widget _recentOrders(DashboardData data, String currency) {
    final orders = data.recentOrders.take(4).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent orders', style: Theme.of(context).textTheme.titleLarge),
            ),
            TextButton(onPressed: () => context.push('/orders'), child: const Text('View all')),
          ],
        ),
        const SizedBox(height: B2BSpacing.sm),
        if (orders.isEmpty)
          const ContentEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'No recent orders',
            message: 'New partner sales will appear here.',
          )
        else
          for (final order in orders) ...[
            B2BSurface(
              child: Row(
                children: [
                  const Icon(Icons.public_rounded, color: AppColors.primary),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          order.createdAt == null
                              ? order.orderNumber
                              : DateFormat('dd MMM · HH:mm').format(order.createdAt!.toLocal()),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money(order.totalAmount, currency),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order.status,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.sm),
          ],
      ],
    );
  }

  Widget _staleBanner() => Container(
        padding: const EdgeInsets.all(B2BSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(B2BRadius.md),
          border: Border.all(color: AppColors.warning.withValues(alpha: .25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.warning),
            SizedBox(width: B2BSpacing.sm),
            Expanded(child: Text('Showing the last available partner dashboard data.')),
          ],
        ),
      );

  String _money(double value, String currency) =>
      NumberFormat.currency(name: currency, symbol: '$currency ').format(value);
}

class _WorkspaceAction {
  const _WorkspaceAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
