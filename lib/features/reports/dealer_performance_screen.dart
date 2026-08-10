import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../partners/dealer_network_data.dart';
import '../partners/dealer_network_repository.dart';

class DealerPerformanceScreen extends StatefulWidget {
  const DealerPerformanceScreen({super.key});

  @override
  State<DealerPerformanceScreen> createState() => _DealerPerformanceScreenState();
}

class _DealerPerformanceScreenState extends State<DealerPerformanceScreen> {
  final _repository = DealerNetworkRepository();
  final _search = TextEditingController();
  List<DealerSummary> _dealers = const [];
  bool _loading = true;
  String? _error;
  String _sort = 'sales';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _dealers.isEmpty;
      _error = null;
    });
    try {
      final result = await _repository.fetchNetwork();
      if (mounted) setState(() => _dealers = result.dealers);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Dealer performance could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DealerSummary> get _visible {
    final query = _search.text.trim().toLowerCase();
    final rows = _dealers.where((dealer) {
      return query.isEmpty || '${dealer.name} ${dealer.email} ${dealer.status}'.toLowerCase().contains(query);
    }).toList();
    rows.sort((a, b) => switch (_sort) {
          'balance' => b.currentBalance.compareTo(a.currentBalance),
          'orders' => b.totalOrders.compareTo(a.totalOrders),
          'clients' => b.totalClients.compareTo(a.totalClients),
          _ => b.totalSales.compareTo(a.totalSales),
        });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visible;
    final sales = _dealers.fold<double>(0, (sum, item) => sum + item.totalSales);
    final balance = _dealers.fold<double>(0, (sum, item) => sum + item.currentBalance);
    final clients = _dealers.fold<int>(0, (sum, item) => sum + item.totalClients);
    final orders = _dealers.fold<int>(0, (sum, item) => sum + item.totalOrders);
    final currency = _dealers.isNotEmpty ? _dealers.first.currency : 'USD';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Dealer Performance'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.sm, B2BSpacing.lg, B2BSpacing.xxl),
          children: [
            Text('Dealer leaderboard', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text('Compare live commercial activity and wallet exposure across your dealer network.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading dealer performance...')
            else if (_error != null && _dealers.isEmpty)
              ContentErrorState(message: _error!, onRetry: _load)
            else ...[
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Network sales', value: '$currency ${sales.toStringAsFixed(0)}', icon: Icons.show_chart_rounded)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Balances', value: '$currency ${balance.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.sm),
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Clients', value: '$clients', icon: Icons.groups_outlined)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Orders', value: '$orders', icon: Icons.shopping_bag_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.lg),
              TextField(
                controller: _search,
                decoration: const InputDecoration(hintText: 'Search dealer', prefixIcon: Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: B2BSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'sales', label: Text('Sales')),
                  ButtonSegment(value: 'orders', label: Text('Orders')),
                  ButtonSegment(value: 'clients', label: Text('Clients')),
                  ButtonSegment(value: 'balance', label: Text('Balance')),
                ],
                selected: {_sort},
                onSelectionChanged: (value) => setState(() => _sort = value.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (rows.isEmpty)
                const ContentEmptyState(icon: Icons.leaderboard_outlined, title: 'No dealer metrics', message: 'Dealer performance will appear when the reseller dealer API returns records.')
              else
                for (var index = 0; index < rows.length; index++) ...[
                  _DealerRankCard(rank: index + 1, dealer: rows[index]),
                  const SizedBox(height: B2BSpacing.sm),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DealerRankCard extends StatelessWidget {
  const _DealerRankCard({required this.rank, required this.dealer});

  final int rank;
  final DealerSummary dealer;

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      onTap: () => context.push('/dealers'),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Text('$rank', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dealer.name, style: const TextStyle(fontWeight: FontWeight.w900)),
            if (dealer.email.isNotEmpty) Text(dealer.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
          ])),
          Text('${dealer.currency} ${dealer.totalSales.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: B2BSpacing.md),
        const Divider(height: 1),
        const SizedBox(height: B2BSpacing.md),
        Row(children: [
          Expanded(child: _Value(label: 'Balance', value: '${dealer.currency} ${dealer.currentBalance.toStringAsFixed(0)}')),
          Expanded(child: _Value(label: 'Orders', value: '${dealer.totalOrders}')),
          Expanded(child: _Value(label: 'Clients', value: '${dealer.totalClients}', end: true)),
        ]),
      ]),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, this.end = false});
  final String label;
  final String value;
  final bool end;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      );
}
