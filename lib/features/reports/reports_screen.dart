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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Reports'),
        actions: [
          IconButton(
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.sm,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            if (_loading && _dashboard == null)
              const ContentLoadingState(label: 'Preparing business reports...')
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
    final averageOrder = completed.isEmpty ? 0 : completedRevenue / completed.length;
    final daily = _dailyRevenue(completed);
    final packages = _topPackages(completed);

    return [
      Text(
        'Business performance',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: B2BSpacing.xs),
      Text(
        'Live sales and order intelligence from your B2B workspace.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: B2BSpacing.xl),
      Row(
        children: [
          Expanded(
            child: B2BMetricCard(
              label: 'Monthly sales',
              value: '${data.currency} ${data.monthlySales.toStringAsFixed(2)}',
              icon: Icons.show_chart_rounded,
            ),
          ),
          const SizedBox(width: B2BSpacing.md),
          Expanded(
            child: B2BMetricCard(
              label: 'Today sales',
              value: '${data.currency} ${data.todaySales.toStringAsFixed(2)}',
              icon: Icons.today_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: B2BSpacing.md),
      Row(
        children: [
          Expanded(
            child: B2BMetricCard(
              label: 'Completed orders',
              value: '${completed.length}',
              icon: Icons.task_alt_rounded,
            ),
          ),
          const SizedBox(width: B2BSpacing.md),
          Expanded(
            child: B2BMetricCard(
              label: 'Average order',
              value: '${data.currency} ${averageOrder.toStringAsFixed(2)}',
              icon: Icons.receipt_long_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: B2BSpacing.xl),
      _SectionTitle(title: 'Revenue trend', caption: 'Last 7 days'),
      const SizedBox(height: B2BSpacing.md),
      B2BSurface(
        child: SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _RevenueChartPainter(daily.map((item) => item.amount).toList()),
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
      const SizedBox(height: B2BSpacing.xl),
      _SectionTitle(title: 'Top packages', caption: '${completed.length} completed orders'),
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
                      revenue: '${data.currency} ${packages[index].revenue.toStringAsFixed(2)}',
                    ),
                    if (index != packages.length - 1)
                      const Divider(height: B2BSpacing.xl),
                  ],
                ],
              ),
      ),
      const SizedBox(height: B2BSpacing.xl),
      _SectionTitle(title: 'eSIM portfolio', caption: 'Current status'),
      const SizedBox(height: B2BSpacing.md),
      B2BSurface(
        child: Row(
          children: [
            Expanded(
              child: _PortfolioValue(
                label: 'Active',
                value: '${data.activeEsimCount}',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: B2BSpacing.md),
            Expanded(
              child: _PortfolioValue(
                label: 'Expired',
                value: '${data.expiredEsimCount}',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

bool _isCompleted(String status) {
  final value = status.toLowerCase();
  return value == 'completed' || value == 'success';
}

List<_DailyRevenue> _dailyRevenue(List<MobileOrderSummary> orders) {
  final now = DateTime.now();
  return List.generate(7, (index) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
    final amount = orders.where((order) {
      final date = order.createdAt?.toLocal();
      return date != null && date.year == day.year && date.month == day.month && date.day == day.day;
    }).fold<double>(0, (sum, order) => sum + order.amount);
    return _DailyRevenue(label: '${day.day}', amount: amount);
  });
}

List<_PackagePerformance> _topPackages(List<MobileOrderSummary> orders) {
  final grouped = <String, _PackagePerformance>{};
  for (final order in orders) {
    final key = order.packageName.trim().isEmpty ? 'eSIM package' : order.packageName.trim();
    final current = grouped[key];
    grouped[key] = _PackagePerformance(
      name: key,
      orders: (current?.orders ?? 0) + 1,
      revenue: (current?.revenue ?? 0) + order.amount,
    );
  }
  final items = grouped.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));
  return items.take(5).toList(growable: false);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.caption});
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({required this.rank, required this.name, required this.orders, required this.revenue});
  final int rank;
  final String name;
  final int orders;
  final String revenue;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primaryLight,
            child: Text('$rank', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: B2BSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('$orders orders', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(revenue, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
}

class _PortfolioValue extends StatelessWidget {
  const _PortfolioValue({required this.label, required this.value, required this.color});
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
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: B2BSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      );
}

class _RevenueChartPainter extends CustomPainter {
  const _RevenueChartPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = AppColors.border;
    for (var i = 0; i < 4; i++) {
      final y = (size.height - 40) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.isEmpty) return;
    final maxValue = math.max(values.reduce(math.max), 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y = (size.height - 50) - ((size.height - 70) * values[i] / maxValue);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) => oldDelegate.values != values;
}

class _DailyRevenue {
  const _DailyRevenue({required this.label, required this.amount});
  final String label;
  final double amount;
}

class _PackagePerformance {
  const _PackagePerformance({required this.name, required this.orders, required this.revenue});
  final String name;
  final int orders;
  final double revenue;
}
