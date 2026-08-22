import 'package:flutter/material.dart';

import '../../shared/widgets/animated_metric_value.dart';
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
import '../../shared/widgets/notification_icon_button.dart';

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
  bool _showingStaleData = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 0),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const ContentLoadingState(label: 'Loading your workspace...');
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
          B2BSpacing.xxl,
        ),
        children: [
          if (_showingStaleData) ...[
            const _StaleDataBanner(),
            const SizedBox(height: B2BSpacing.md),
          ],
          _PremiumHeader(
            role: data.role,
            onNotificationsTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: B2BSpacing.lg),
          _WalletHero(data: data),
          const SizedBox(height: B2BSpacing.lg),
          _KpiGrid(data: data),
          const SizedBox(height: B2BSpacing.xl),
          const _SectionHeader(title: 'Quick actions'),
          const SizedBox(height: B2BSpacing.md),
          const _QuickActions(),
          const SizedBox(height: B2BSpacing.xl),
          _SalesOverview(data: data),
          const SizedBox(height: B2BSpacing.xl),
          _SectionHeader(
            title: 'Recent orders',
            actionLabel: 'View all',
            onAction: () => context.go('/orders'),
          ),
          const SizedBox(height: B2BSpacing.md),
          _RecentOrders(orders: data.recentOrders, currency: data.currency),
        ],
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({required this.role, required this.onNotificationsTap});

  final String role;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final roleLabel = role.trim().isEmpty ? 'Partner' : role;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: B2BSpacing.xs),
              Text(
                'Partner 👋',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: B2BSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
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
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        NotificationIconButton(onTap: onNotificationsTap),
      ],
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
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
                  'Available wallet balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          AnimatedMetricValue(
            value: '${data.currency} ${data.balance.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ready for new eSIM orders',
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

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return DashboardKpiLayout(
      children: [
        B2BMetricCard(
          label: 'Total eSIMs',
          value: '${data.totalEsimCount}',
          icon: Icons.sim_card_rounded,
          trend: 'All eSIMs',
          trendPositive: true,
        ),
        B2BMetricCard(
          label: 'Total Sales',
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

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.add_shopping_cart_rounded, 'New order', '/packages'),
      (Icons.public_rounded, 'Buy eSIM', '/packages'),
      (Icons.account_balance_wallet_outlined, 'Wallet', '/wallet'),
      (Icons.groups_2_outlined, 'Customers', '/customers'),
      (Icons.sim_card_rounded, 'SIM Tools', '/sim-tools'),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SalesOverview extends StatelessWidget {
  const _SalesOverview({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final points = <double>[
      data.todaySales * .42,
      data.todaySales * .58,
      data.todaySales * .51,
      data.todaySales * .72,
      data.todaySales * .64,
      data.todaySales * .83,
      data.todaySales,
    ];

    return B2BSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Sales overview'),
          const SizedBox(height: B2BSpacing.sm),
          Text(
            '${data.currency} ${data.monthlySales.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: B2BSpacing.xs),
          Text(
            'Current month revenue trend',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: B2BSpacing.lg),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(painter: _SalesSparklinePainter(points)),
          ),
        ],
      ),
    );
  }
}

class _SalesSparklinePainter extends CustomPainter {
  const _SalesSparklinePainter(this.points);

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxValue = points.reduce((a, b) => a > b ? a : b);
    final minValue = points.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).abs() < .001
        ? 1.0
        : maxValue - minValue;
    final path = Path();

    for (var index = 0; index < points.length; index++) {
      final x = size.width * index / (points.length - 1);
      final normalized = (points[index] - minValue) / range;
      final y = size.height - (normalized * (size.height - 18)) - 9;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x332563EB), Color(0x002563EB)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SalesSparklinePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

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
        message: 'Your latest mobile orders will appear here.',
        actionLabel: 'Browse packages',
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
                      fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(
        horizontal: B2BSpacing.md,
        vertical: B2BSpacing.md,
      ),
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
