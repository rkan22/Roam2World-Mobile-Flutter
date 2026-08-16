import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../dashboard/dashboard_data.dart';
import '../dashboard/dashboard_repository.dart';
import '../orders/order_history.dart';
import '../orders/orders_repository.dart';
import 'widgets/reports_adaptive_sections.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _dashboardRepository = DashboardRepository();
  final _ordersRepository = OrdersRepository();

  DashboardData? _dashboard;
  List<MobileOrderSummary> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = _dashboard == null;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _dashboardRepository.fetchDashboard(forceRefresh: forceRefresh),
        _ordersRepository.fetchOrders(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as DashboardData;
        _orders = (results[1] as OrderHistory).orders;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Reports could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _Header(
                onBack: () => context.pop(),
                onRefresh: () => _load(forceRefresh: true),
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (_loading && _dashboard == null)
                const ContentLoadingState(
                  label: 'Preparing business reports...',
                )
              else if (_error != null && _dashboard == null)
                ContentErrorState(
                  message: _error!,
                  onRetry: () => _load(forceRefresh: true),
                )
              else if (_dashboard != null)
                ..._content(_dashboard!),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(DashboardData data) {
    final completed = _orders
        .where((order) => _isCompleted(order.status))
        .toList(growable: false);
    final completedRevenue = completed.fold<double>(
      0,
      (sum, order) => sum + order.amount,
    );
    final averageOrder = completed.isEmpty
        ? 0
        : completedRevenue / completed.length;
    final daily = _dailyRevenue(completed);
    final packages = _topPackages(completed);

    return [
      _ReportHero(
        currency: data.currency,
        monthlySales: data.monthlySales,
        todaySales: data.todaySales,
        completedOrders: completed.length,
      ),
      const SizedBox(height: B2BSpacing.lg),
      ReportsKpiLayout(
        children: [
          B2BMetricCard(
            label: 'Monthly sales',
            value: '${data.currency} ${data.monthlySales.toStringAsFixed(2)}',
            icon: Icons.show_chart_rounded,
          ),
          B2BMetricCard(
            label: 'Today sales',
            value: '${data.currency} ${data.todaySales.toStringAsFixed(2)}',
            icon: Icons.today_rounded,
          ),
          B2BMetricCard(
            label: 'Completed orders',
            value: '${completed.length}',
            icon: Icons.task_alt_rounded,
          ),
          B2BMetricCard(
            label: 'Average order',
            value: '${data.currency} ${averageOrder.toStringAsFixed(2)}',
            icon: Icons.receipt_long_rounded,
          ),
        ],
      ),
      const SizedBox(height: B2BSpacing.xl),
      ReportsInsightsLayout(
        primary: _RevenuePanel(daily: daily),
        secondary: _PackagesPanel(
          packages: packages,
          completedOrders: completed.length,
          currency: data.currency,
        ),
      ),
      const SizedBox(height: B2BSpacing.xl),
      _PortfolioCard(
        active: data.activeEsimCount,
        expired: data.expiredEsimCount,
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: B2BSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: B2BSpacing.xxs),
              Text(
                'Live B2B sales intelligence',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _ReportHero extends StatelessWidget {
  const _ReportHero({
    required this.currency,
    required this.monthlySales,
    required this.todaySales,
    required this.completedOrders,
  });

  final String currency;
  final double monthlySales;
  final double todaySales;
  final int completedOrders;

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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: B2BSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business performance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sales, orders and eSIM portfolio health',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.xl),
          Text(
            '$currency ${monthlySales.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: B2BSpacing.xs),
          const Text(
            'Monthly sales volume',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Today',
                  value: '$currency ${todaySales.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: _HeroStat(
                  label: 'Completed',
                  value: '$completedOrders orders',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(B2BSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(B2BRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel({required this.daily});

  final List<_DailyRevenue> daily;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Revenue trend', caption: 'Last 7 days'),
        const SizedBox(height: B2BSpacing.md),
        B2BSurface(
          child: SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _RevenueChartPainter(
                daily.map((item) => item.amount).toList(),
                Theme.of(context).colorScheme.outlineVariant,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 170),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: daily
                      .map(
                        (item) => Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PackagesPanel extends StatelessWidget {
  const _PackagesPanel({
    required this.packages,
    required this.completedOrders,
    required this.currency,
  });

  final List<_PackagePerformance> packages;
  final int completedOrders;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Top packages',
          caption: '$completedOrders completed orders',
        ),
        const SizedBox(height: B2BSpacing.md),
        B2BSurface(
          child: packages.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: B2BSpacing.xl),
                  child: Text('Completed order data will appear here.'),
                )
              : Column(
                  children: [
                    for (var index = 0; index < packages.length; index++) ...[
                      _PackageRow(
                        rank: index + 1,
                        name: packages[index].name,
                        orders: packages[index].orders,
                        revenue:
                            '$currency ${packages[index].revenue.toStringAsFixed(2)}',
                      ),
                      if (index != packages.length - 1)
                        const Divider(height: B2BSpacing.xl),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.active, required this.expired});

  final int active;
  final int expired;

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'eSIM portfolio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              const Text(
                'Live status',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PortfolioValue(
                  label: 'Active',
                  value: '$active',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: B2BSpacing.md),
              Expanded(
                child: _PortfolioValue(
                  label: 'Expired',
                  value: '$expired',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _isCompleted(String status) {
  final value = status.toLowerCase();
  return value == 'completed' || value == 'success';
}

List<_DailyRevenue> _dailyRevenue(List<MobileOrderSummary> orders) {
  final now = DateTime.now();
  return List.generate(7, (index) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: 6 - index));
    final amount = orders
        .where((order) {
          final date = order.createdAt?.toLocal();
          return date != null &&
              date.year == day.year &&
              date.month == day.month &&
              date.day == day.day;
        })
        .fold<double>(0, (sum, order) => sum + order.amount);
    return _DailyRevenue(label: '${day.day}', amount: amount);
  });
}

List<_PackagePerformance> _topPackages(List<MobileOrderSummary> orders) {
  final grouped = <String, _PackagePerformance>{};
  for (final order in orders) {
    final key = order.packageName.trim().isEmpty
        ? 'eSIM package'
        : order.packageName.trim();
    final current = grouped[key];
    grouped[key] = _PackagePerformance(
      name: key,
      orders: (current?.orders ?? 0) + 1,
      revenue: (current?.revenue ?? 0) + order.amount,
    );
  }
  final items = grouped.values.toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));
  return items.take(5).toList(growable: false);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      Text(caption, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({
    required this.rank,
    required this.name,
    required this.orders,
    required this.revenue,
  });

  final int rank;
  final String name;
  final int orders;
  final String revenue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            '$rank',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: B2BSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '$orders orders',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(revenue, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _PortfolioValue extends StatelessWidget {
  const _PortfolioValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(B2BSpacing.md),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(B2BRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: B2BSpacing.xs),
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
      ],
    ),
  );
}

class _RevenueChartPainter extends CustomPainter {
  const _RevenueChartPainter(this.values, this.gridColor);

  final List<double> values;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = gridColor;
    for (var i = 0; i < 4; i++) {
      final y = (size.height - 40) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.isEmpty) return;
    final maxValue = math.max(values.reduce(math.max), 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y =
          (size.height - 50) - ((size.height - 70) * values[i] / maxValue);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.gridColor != gridColor;
}

class _DailyRevenue {
  const _DailyRevenue({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _PackagePerformance {
  const _PackagePerformance({
    required this.name,
    required this.orders,
    required this.revenue,
  });

  final String name;
  final int orders;
  final double revenue;
}
