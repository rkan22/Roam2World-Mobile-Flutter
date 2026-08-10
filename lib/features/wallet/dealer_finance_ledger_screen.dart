import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'wallet_data.dart';
import 'wallet_repository.dart';

class DealerFinanceLedgerScreen extends StatefulWidget {
  const DealerFinanceLedgerScreen({super.key});

  @override
  State<DealerFinanceLedgerScreen> createState() => _DealerFinanceLedgerScreenState();
}

class _DealerFinanceLedgerScreenState extends State<DealerFinanceLedgerScreen> {
  final _repository = WalletRepository();
  final _search = TextEditingController();
  WalletData? _wallet;
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = _wallet == null;
      _error = null;
    });
    try {
      final wallet = await _repository.fetchWallet(forceRefresh: force);
      if (mounted) setState(() => _wallet = wallet);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Dealer finance ledger could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<WalletTransaction> _rows(WalletData wallet) {
    final query = _search.text.trim().toLowerCase();
    return wallet.transactions.where((item) {
      final typeMatch = switch (_filter) {
        'credits' => item.normalizedType == 'credit',
        'debits' => item.normalizedType == 'debit',
        'refunds' => item.normalizedType == 'refund',
        'failed' => item.status.toLowerCase() == 'failed',
        _ => true,
      };
      if (!typeMatch) return false;
      if (query.isEmpty) return true;
      return [
        item.reference,
        item.description,
        item.provider,
        item.orderNumber,
        item.status,
      ].join(' ').toLowerCase().contains(query);
    }).toList(growable: false);
  }

  String _money(double value, String currency) =>
      NumberFormat.currency(name: currency, symbol: '$currency ').format(value);

  Future<void> _requestBalance(WalletData wallet) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final key = GlobalKey<FormState>();
    var submitting = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            0,
            B2BSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + B2BSpacing.xl,
          ),
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request balance', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: B2BSpacing.xs),
                const Text(
                  'Send a funding request to your reseller. Balance changes only after approval.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: B2BSpacing.lg),
                TextFormField(
                  controller: amount,
                  enabled: !submitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Requested amount',
                    prefixText: '${wallet.currency} ',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed <= 0) return 'Enter an amount greater than zero.';
                    return null;
                  },
                ),
                const SizedBox(height: B2BSpacing.md),
                TextFormField(
                  controller: note,
                  enabled: !submitting,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
                if (error != null) ...[
                  const SizedBox(height: B2BSpacing.sm),
                  Text(error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: B2BSpacing.lg),
                ElevatedButton.icon(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!(key.currentState?.validate() ?? false)) return;
                          setSheetState(() {
                            submitting = true;
                            error = null;
                          });
                          try {
                            final request = await _repository.createDealerBalanceRequest(
                              amount: double.parse(amount.text.trim()),
                              currency: wallet.currency,
                              note: note.text,
                            );
                            if (!mounted || !sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${request.currency} ${request.amount.toStringAsFixed(2)} request submitted · ${request.status}',
                                ),
                              ),
                            );
                            await _load(force: true);
                          } on ApiException catch (apiError) {
                            setSheetState(() => error = apiError.message);
                          } finally {
                            if (sheetContext.mounted) setSheetState(() => submitting = false);
                          }
                        },
                  icon: const Icon(Icons.add_card_rounded),
                  label: Text(submitting ? 'Submitting...' : 'Send request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    amount.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Ledger'),
        actions: [IconButton(onPressed: () => _load(force: true), icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.xs, B2BSpacing.lg, B2BSpacing.xxl),
          children: [
            Text('Dealer wallet', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Track reseller-funded balance, purchases, refunds and adjustments.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && _wallet == null)
              const ContentLoadingState(label: 'Loading dealer wallet...')
            else if (_error != null && _wallet == null)
              ContentErrorState(message: _error!, onRetry: () => _load(force: true))
            else if (_wallet != null)
              _content(_wallet!),
          ],
        ),
      ),
    );
  }

  Widget _content(WalletData wallet) {
    final rows = _rows(wallet);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        B2BSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available balance', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
              const SizedBox(height: B2BSpacing.xs),
              Text(
                _money(wallet.availableAmount, wallet.currency),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: B2BSpacing.sm),
              Text('${wallet.secondaryLabel}: ${_money(wallet.secondaryAmount, wallet.currency)}'),
              const SizedBox(height: B2BSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => _requestBalance(wallet),
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Request balance'),
              ),
            ],
          ),
        ),
        const SizedBox(height: B2BSpacing.md),
        Row(
          children: [
            Expanded(
              child: B2BMetricCard(
                label: 'Credits',
                value: _money(wallet.totalCredits, wallet.currency),
                icon: Icons.north_east_rounded,
              ),
            ),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(
              child: B2BMetricCard(
                label: 'Debits',
                value: _money(wallet.totalDebits, wallet.currency),
                icon: Icons.south_west_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: B2BSpacing.xl),
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            hintText: 'Search transaction, order or provider',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: B2BSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in const [
                ('all', 'All'),
                ('credits', 'Credits'),
                ('debits', 'Debits'),
                ('refunds', 'Refunds'),
                ('failed', 'Failed'),
              ]) ...[
                ChoiceChip(
                  label: Text(item.$2),
                  selected: _filter == item.$1,
                  onSelected: (_) => setState(() => _filter = item.$1),
                ),
                const SizedBox(width: B2BSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: B2BSpacing.md),
        if (rows.isEmpty)
          const ContentEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No wallet activity',
            message: 'Dealer funding and order deductions will appear here.',
          )
        else
          for (final row in rows) ...[
            B2BSurface(
              child: Row(
                children: [
                  Icon(
                    row.isCredit ? Icons.north_east_rounded : Icons.south_west_rounded,
                    color: row.isCredit ? AppColors.success : AppColors.textSecondary,
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.description.isEmpty ? row.type : row.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (row.orderNumber.isNotEmpty || row.reference.isNotEmpty)
                          Text(
                            [row.orderNumber, row.reference].where((value) => value.isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Text(
                    '${row.isCredit ? '+' : '-'}${_money(row.absoluteAmount, row.currency)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: row.isCredit ? AppColors.success : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.sm),
          ],
      ],
    );
  }
}
