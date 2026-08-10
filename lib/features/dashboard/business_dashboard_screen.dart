import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/routing/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'dashboard_data.dart';
import 'dashboard_repository.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({
    super.key,
    required this.role,
    this.repository,
  });

  final AppRole role;
  final DashboardRepository? repository;

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  late final DashboardRepository _repository;
  DashboardData? _data;
  Object? _error;
  bool _loading = true;
  bool _showingStaleData = false;
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
        _showingStaleData = _repository.lastFetchUsedStale;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
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
      backgroundColor: AppColors.background,
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              if (_showingStaleData) ...[
                _staleBanner(),
                const SizedBox(height: 12),
              ],
              _header(),
              const SizedBox(height: 18),
              if (_loading && _data == null)
                const ContentLoadingState(label: 'Loading dashboard...')
              else if (_error != null && _data == null)
                ContentErrorState(
                  message: _error is ApiException
                      ? (_error! as ApiException).message
                      : 'Dashboard could not be loaded.',
                  onRetry: () => _load(forceRefresh: true),
                )
              else if (_data != null) ...[
                _walletHero(_data!),
                const SizedBox(height: 14),
                _metricStrip(_data!),
                const SizedBox(height: 14),
                _recentOrders(_data!),
                const SizedBox(height: 14),
                _quickActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final role = widget.role.label;
    return Row(
      children: [
        _SquareIconButton(
          icon: Icons.menu_rounded,
          onTap: () => context.push('/profile'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, $role',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                _subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _SquareIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              role.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _walletHero(DashboardData data) {
    final currency = data.currency.trim().isEmpty ? 'USD' : data.currency;
    final balance = _balanceVisible ? _money(data.balance, currency) : '••••••••';

    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroStart, AppColors.heroMiddle, AppColors.heroEnd],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: B2BShadows.hero,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -54,
            top: -54,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _balanceLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        balance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1,
                          letterSpacing: -0.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currency,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 38,
                        child: FilledButton.icon(
                          onPressed: () => context.push(_primaryHeroRoute),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(_primaryHeroIcon, size: 17),
                          label: Text(_primaryHeroLabel),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 102,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A24),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.public_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Roam2World',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                onPressed: () => setState(() => _balanceVisible = !_balanceVisible),
                                icon: Icon(
                                  _balanceVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 15,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '${widget.role.label.toUpperCase()} WALLET',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              letterSpacing: .9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Secure business balance',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricStrip(DashboardData data) {
    final currency = data.currency.trim().isEmpty ? 'USD' : data.currency;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        B2BMetricCard(
          label: 'Today sales',
          value: _money(data.todaySales, currency),
          icon: Icons.today_rounded,
        ),
        B2BMetricCard(
          label: 'Monthly sales',
          value: _money(data.monthlySales, currency),
          icon: Icons.trending_up_rounded,
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
    );
  }

  Widget _recentOrders(DashboardData data) {
    final currency = data.currency.trim().isEmpty ? 'USD' : data.currency;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Recent orders', style: Theme.of(context).textTheme.titleLarge),
              ),
              TextButton(
                onPressed: () => context.go('/orders'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (data.recentOrders.isEmpty)
            const ContentEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No recent orders',
              message: 'Recent orders will appear here.',
            )
          else
            for (var index = 0;
                index < data.recentOrders.length && index < 4;
                index++) ...[
              _OrderRow(
                order: data.recentOrders[index],
                amount: _money(data.recentOrders[index].totalAmount, currency),
                onTap: () => context.go('/orders'),
              ),
              if (index < data.recentOrders.length - 1 && index < 3)
                const Divider(height: 18),
            ],
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = _actions;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.45,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.go(action.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(action.icon, size: 20, color: AppColors.primary),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String get _subtitle => switch (widget.role) {
        AppRole.admin => 'Here’s what’s happening across the platform today.',
        AppRole.reseller => 'Here’s what’s happening with your reseller business today.',
        AppRole.dealer => 'Here’s what’s happening with your dealer business today.',
        _ => 'Here’s what’s happening with your business today.',
      };

  String get _balanceLabel => switch (widget.role) {
        AppRole.reseller => 'Available Credit',
        AppRole.dealer => 'Available Balance',
        _ => 'Wallet Balance',
      };

  String get _primaryHeroLabel => switch (widget.role) {
        AppRole.admin => 'Operations',
        AppRole.reseller => 'Add Funds',
        AppRole.dealer => 'Add Funds',
        _ => 'Wallet',
      };

  IconData get _primaryHeroIcon => switch (widget.role) {
        AppRole.admin => Icons.monitor_heart_outlined,
        _ => Icons.add_rounded,
      };

  String get _primaryHeroRoute => switch (widget.role) {
        AppRole.admin => '/operations',
        _ => '/wallet',
      };

  List<_DashboardAction> get _actions => switch (widget.role) {
        AppRole.admin => const [
            _DashboardAction('Orders', Icons.receipt_long_outlined, '/orders'),
            _DashboardAction('Operations', Icons.monitor_heart_outlined, '/operations'),
            _DashboardAction('Reports', Icons.analytics_outlined, '/reports'),
            _DashboardAction('eSIMs', Icons.sim_card_outlined, '/esims'),
            _DashboardAction('Catalog', Icons.inventory_2_outlined, '/packages'),
            _DashboardAction('Wallet', Icons.account_balance_wallet_outlined, '/wallet'),
          ],
        AppRole.reseller => const [
            _DashboardAction('Dealer Network', Icons.storefront_outlined, '/dealers'),
            _DashboardAction('Dealer Pricing', Icons.percent_rounded, '/dealers/pricing'),
            _DashboardAction('Finance', Icons.account_balance_wallet_outlined, '/finance'),
            _DashboardAction('Operations', Icons.monitor_heart_outlined, '/operations'),
            _DashboardAction('Clients', Icons.groups_outlined, '/clients'),
            _DashboardAction('Reports', Icons.analytics_outlined, '/reports'),
          ],
        AppRole.dealer => const [
            _DashboardAction('Customer Pricing', Icons.percent_rounded, '/pricing/customer'),
            _DashboardAction('Finance', Icons.account_balance_wallet_outlined, '/finance'),
            _DashboardAction('Clients', Icons.groups_outlined, '/clients'),
            _DashboardAction('Orders', Icons.receipt_long_outlined, '/orders'),
            _DashboardAction('eSIMs', Icons.sim_card_outlined, '/esims'),
            _DashboardAction('Reports', Icons.analytics_outlined, '/reports'),
          ],
        _ => const [],
      };

  String _money(double value, String currency) {
    return NumberFormat.currency(name: currency, symbol: '$currency ').format(value);
  }

  Widget _staleBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text('Showing the latest cached data. Pull to refresh.'),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Icon(icon, size: 21),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.amount,
    required this.onTap,
  });

  final DashboardOrderSummary order;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.primary),
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
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.orderNumber,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
