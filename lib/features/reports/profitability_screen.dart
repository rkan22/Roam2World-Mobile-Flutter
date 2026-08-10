import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../wallet/wallet_data.dart';
import '../wallet/wallet_repository.dart';

class ProfitabilityScreen extends StatefulWidget {
  const ProfitabilityScreen({super.key});

  @override
  State<ProfitabilityScreen> createState() => _ProfitabilityScreenState();
}

class _ProfitabilityScreenState extends State<ProfitabilityScreen> {
  final _repository = WalletRepository();
  final _search = TextEditingController();
  WalletData? _wallet;
  bool _loading = true;
  String? _error;
  String? _provider;

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
      _loading = _wallet == null;
      _error = null;
    });
    try {
      final result = await _repository.fetchWallet(forceRefresh: true);
      if (mounted) setState(() => _wallet = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Profitability data could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<WalletTransaction> get _rows {
    final wallet = _wallet;
    if (wallet == null) return const [];
    final query = _search.text.trim().toLowerCase();
    return wallet.transactions.where((item) {
      if (!item.hasProfitability) return false;
      final providerMatches = _provider == null || item.provider == _provider;
      final text = [item.provider, item.packageName, item.orderNumber, item.reference].join(' ').toLowerCase();
      return providerMatches && (query.isEmpty || text.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet;
    final rows = _rows;
    final providers = wallet?.transactions
            .where((item) => item.hasProfitability && item.provider.isNotEmpty)
            .map((item) => item.provider)
            .toSet()
            .toList() ??
        <String>[];
    providers.sort();
    final sales = rows.fold<double>(0, (sum, item) => sum + (item.salePrice ?? 0));
    final cost = rows.fold<double>(0, (sum, item) => sum + (item.costPrice ?? 0));
    final margin = sales - cost;
    final marginRate = sales > 0 ? margin / sales * 100 : 0;
    final lowMargin = rows.where((item) {
      final rate = item.grossMarginRate;
      return rate != null && rate > 0 && rate < 12;
    }).length;
    final currency = wallet?.currency ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Profitability'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.sm, B2BSpacing.lg, B2BSpacing.xxl),
          children: [
            Text('Provider profitability', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text('Margins are calculated only when the transaction payload includes both sale and provider cost fields.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading profitability...')
            else if (_error != null && wallet == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else ...[
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Sales', value: '$currency ${sales.toStringAsFixed(2)}', icon: Icons.payments_outlined)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Provider cost', value: '$currency ${cost.toStringAsFixed(2)}', icon: Icons.layers_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.sm),
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Gross margin', value: '$currency ${margin.toStringAsFixed(2)}', icon: Icons.trending_up_rounded)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Margin rate', value: '${marginRate.toStringAsFixed(1)}%', icon: Icons.percent_rounded)),
              ]),
              const SizedBox(height: B2BSpacing.lg),
              TextField(
                controller: _search,
                decoration: const InputDecoration(hintText: 'Search provider, plan or order', prefixIcon: Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: B2BSpacing.sm),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: providers.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: B2BSpacing.xs),
                  itemBuilder: (context, index) {
                    final value = index == 0 ? null : providers[index - 1];
                    return ChoiceChip(label: Text(value ?? 'All providers'), selected: _provider == value, onSelected: (_) => setState(() => _provider = value));
                  },
                ),
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (rows.isEmpty)
                const ContentEmptyState(
                  icon: Icons.query_stats_outlined,
                  title: 'Provider cost data unavailable',
                  message: 'Profitability will appear when mobile transaction/order payloads include both sale and provider cost fields.',
                )
              else ...[
                B2BSurface(
                  showShadow: false,
                  backgroundColor: lowMargin > 0 ? AppColors.warning.withValues(alpha: .08) : AppColors.success.withValues(alpha: .08),
                  borderColor: lowMargin > 0 ? AppColors.warning.withValues(alpha: .3) : AppColors.success.withValues(alpha: .3),
                  child: Row(children: [
                    Icon(lowMargin > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: lowMargin > 0 ? AppColors.warning : AppColors.success),
                    const SizedBox(width: B2BSpacing.sm),
                    Expanded(child: Text(lowMargin > 0 ? '$lowMargin rows are below 12% margin.' : 'No low-margin rows in this view.', style: const TextStyle(fontWeight: FontWeight.w800))),
                  ]),
                ),
                const SizedBox(height: B2BSpacing.md),
                for (final item in rows) ...[
                  _ProfitRow(transaction: item, currency: currency),
                  const SizedBox(height: B2BSpacing.sm),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfitRow extends StatelessWidget {
  const _ProfitRow({required this.transaction, required this.currency});
  final WalletTransaction transaction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final margin = transaction.grossMargin ?? 0;
    final rate = transaction.grossMarginRate ?? 0;
    final low = rate > 0 && rate < 12;
    return B2BSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(transaction.provider.isEmpty ? 'Provider' : transaction.provider, style: const TextStyle(fontWeight: FontWeight.w900)),
            if (transaction.packageName.isNotEmpty) Text(transaction.packageName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: (low ? AppColors.danger : AppColors.success).withValues(alpha: .1), borderRadius: BorderRadius.circular(B2BRadius.pill)),
            child: Text('${rate.toStringAsFixed(1)}%', style: TextStyle(color: low ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: B2BSpacing.md),
        Row(children: [
          Expanded(child: _Amount(label: 'Sale', value: '$currency ${(transaction.salePrice ?? 0).toStringAsFixed(2)}')),
          Expanded(child: _Amount(label: 'Cost', value: '$currency ${(transaction.costPrice ?? 0).toStringAsFixed(2)}')),
          Expanded(child: _Amount(label: 'Margin', value: '$currency ${margin.toStringAsFixed(2)}', end: true)),
        ]),
      ]),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value, this.end = false});
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
