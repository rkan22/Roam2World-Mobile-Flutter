import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
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
      if (mounted) setState(() => _error = 'Admin dashboard could not be loaded.');
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
                const _StaleBanner(),
              ],
              const SizedBox(height: B2BSpacing.lg),
              if (_loading && _data == null)
                const ContentLoadingState(label: 'Loading admin workspace...')
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
                Text('Admin Workspace', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: B2BSpacing.xxs),
                Text(
                  'Live platform sales, eSIM and operational activity.',
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
    final balance = _balanceVisible ? _money(data.balance, currency) : '••••••';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
                  const Text(
                    'PLATFORM OVERVIEW',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
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
              const SizedBox(height: B2BSpacing.sm),
              const Text(
                'Available balance',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: B2BSpacing.xs),
              Text(
                balance,
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
                    onPressed: () => context.go('/orders'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Orders'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/operations'),
                    icon: const Icon(Icons.monitor_heart_outlined),
                    label: const Text('Operations'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        Text('Admin controls', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: B2BSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: B2BSpacing.sm,
          mainAxisSpacing: B2BSpacing.sm,
          childAspectRatio: 2.2,
          children: [
            _AdminAction('Orders', Icons.receipt_long_outlined, '/orders'),
            _AdminAction('Operations', Icons.monitor_heart_outlined, '/operations'),
            _AdminAction('Reports', Icons.analytics_outlined, '/reports'),
            _AdminAction('eSIMs', Icons.sim_card_outlined, '/esims'),
            _AdminAction('Catalog', Icons.inventory_2_outlined, '/packages'),
            _AdminAction('Wallet', Icons.account_balance_wallet_outlined, '/wallet'),
          ],
        ),
        const SizedBox(height: B2BSpacing.xl),
        Text('Recent orders', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: B2BSpacing.sm),
        if (data.recentOrders.isEmpty)
          const ContentEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No recent orders',
            message: 'Recent platform orders will appear here.',
          )
        else
          for (final order in data.recentOrders.take(5)) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.shopping_bag_outlined)),
              title: Text(order.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(order.orderNumber),
              trailing: Text(
                _money(order.totalAmount, currency),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () => context.go('/orders'),
            ),
            const Divider(),
          ],
      ],
    );
  }

  String _money(double value, String currency) {
    return NumberFormat.currency(name: currency, symbol: '$currency ').format(value);
  }
}

class _AdminAction extends StatelessWidget {
  const _AdminAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(B2BRadius.lg),
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(B2BSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(B2BRadius.lg),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(B2BSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(B2BRadius.md),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.warning),
          SizedBox(width: B2BSpacing.xs),
          Expanded(child: Text('Showing the latest cached dashboard data. Pull to refresh.')),
        ],
      ),
    );
  }
}
