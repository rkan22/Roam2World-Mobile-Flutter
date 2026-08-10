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

class ResellerFinanceLedgerScreen extends StatefulWidget {
  const ResellerFinanceLedgerScreen({super.key});

  @override
  State<ResellerFinanceLedgerScreen> createState() =>
      _ResellerFinanceLedgerScreenState();
}

class _ResellerFinanceLedgerScreenState
    extends State<ResellerFinanceLedgerScreen> {
  final _repository = WalletRepository();
  final _searchController = TextEditingController();
  WalletData? _wallet;
  bool _loading = true;
  bool _showingStaleData = false;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = _wallet == null;
      _error = null;
    });
    try {
      final wallet = await _repository.fetchWallet(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _showingStaleData = _repository.lastFetchUsedStale;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Finance ledger could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<WalletTransaction> _visibleTransactions(WalletData wallet) {
    final search = _searchController.text.trim().toLowerCase();
    return wallet.transactions.where((transaction) {
      final status = transaction.status.toLowerCase();
      final matchesType = switch (_filter) {
        'credits' => transaction.normalizedType == 'credit',
        'debits' => transaction.normalizedType == 'debit',
        'refunds' => transaction.normalizedType == 'refund',
        'failed' => status == 'failed',
        _ => true,
      };
      if (!matchesType) return false;
      if (search.isEmpty) return true;
      final haystack = [
        transaction.reference,
        transaction.description,
        transaction.type,
        transaction.status,
        transaction.provider,
        transaction.orderNumber,
      ].join(' ').toLowerCase();
      return haystack.contains(search);
    }).toList(growable: false);
  }

  String _money(double amount, String currency) =>
      NumberFormat.currency(name: currency, symbol: '$currency ')
          .format(amount);

  Future<void> _showTopUpRequest(WalletData wallet) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var submitting = false;
    String? submitError;
    double? quickAmount;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> submit() async {
            if (!(formKey.currentState?.validate() ?? false) || submitting) {
              return;
            }
            setSheetState(() {
              submitting = true;
              submitError = null;
            });
            try {
              final request = await _repository.createTopUpRequest(
                amount: double.parse(amountController.text.trim()),
                currency: wallet.currency,
                note: noteController.text,
              );
              if (!mounted || !sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${request.currency} ${request.amount.toStringAsFixed(2)} top-up request created · ${request.status}',
                  ),
                ),
              );
              await _load(forceRefresh: true);
            } on ApiException catch (error) {
              setSheetState(() => submitError = error.message);
            } catch (_) {
              setSheetState(
                () => submitError = 'Top-up request could not be created.',
              );
            } finally {
              if (sheetContext.mounted) {
                setSheetState(() => submitting = false);
              }
            }
          }

          const quickAmounts = [50.0, 100.0, 200.0, 500.0, 1000.0, 2000.0];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              B2BSpacing.lg,
              B2BSpacing.xxs,
              B2BSpacing.lg,
              MediaQuery.viewInsetsOf(context).bottom + B2BSpacing.xl,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request wallet top-up',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  const Text(
                    'Submit a balance request for approval. Your available wallet changes after approval.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: B2BSpacing.lg),
                  Wrap(
                    spacing: B2BSpacing.xs,
                    runSpacing: B2BSpacing.xs,
                    children: [
                      for (final amount in quickAmounts)
                        ChoiceChip(
                          label: Text('${wallet.currency} ${amount.toStringAsFixed(0)}'),
                          selected: quickAmount == amount,
                          onSelected: submitting
                              ? null
                              : (_) {
                                  setSheetState(() {
                                    quickAmount = amount;
                                    amountController.text = amount.toStringAsFixed(0);
                                  });
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: B2BSpacing.md),
                  TextFormField(
                    controller: amountController,
                    enabled: !submitting,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${wallet.currency} ',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter an amount greater than zero.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: B2BSpacing.md),
                  TextFormField(
                    controller: noteController,
                    enabled: !submitting,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                  ),
                  if (submitError != null) ...[
                    const SizedBox(height: B2BSpacing.sm),
                    Text(
                      submitError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: B2BSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: submitting ? null : submit,
                      icon: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_card_rounded),
                      label: Text(submitting ? 'Submitting...' : 'Send top-up request'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    amountController.dispose();
    noteController.dispose();
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
              _Header(onRefresh: () => _load(forceRefresh: true)),
              if (_showingStaleData) ...[
                const SizedBox(height: B2BSpacing.md),
                const _StaleBanner(),
              ],
              const SizedBox(height: B2BSpacing.lg),
              if (_loading && _wallet == null)
                const ContentLoadingState(label: 'Loading finance ledger...')
              else if (_error != null && _wallet == null)
                ContentErrorState(
                  message: _error!,
                  onRetry: () => _load(forceRefresh: true),
                )
              else if (_wallet != null)
                _content(_wallet!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(WalletData wallet) {
    final rows = _visibleTransactions(wallet);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BalanceHero(
          wallet: wallet,
          balance: _money(wallet.availableAmount, wallet.currency),
          netMovement: _money(wallet.netMovement, wallet.currency),
          onTopUp: () => _showTopUpRequest(wallet),
        ),
        const SizedBox(height: B2BSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: B2BSpacing.sm,
          mainAxisSpacing: B2BSpacing.sm,
          childAspectRatio: 1.2,
          children: [
            B2BMetricCard(
              label: 'Debits',
              value: _money(wallet.totalDebits, wallet.currency),
              icon: Icons.south_west_rounded,
            ),
            B2BMetricCard(
              label: 'Credits',
              value: _money(wallet.totalCredits, wallet.currency),
              icon: Icons.north_east_rounded,
            ),
            B2BMetricCard(
              label: 'Refunds',
              value: _money(wallet.totalRefunds, wallet.currency),
              icon: Icons.undo_rounded,
            ),
            B2BMetricCard(
              label: 'Failed',
              value: '${wallet.failedCount}',
              icon: Icons.error_outline_rounded,
            ),
          ],
        ),
        const SizedBox(height: B2BSpacing.xl),
        Text('Transaction ledger', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: B2BSpacing.xs),
        Text(
          'Order deductions, top-ups, refunds and wallet adjustments.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: B2BSpacing.md),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search order, reference or provider',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: B2BSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in const [
                ('all', 'All'),
                ('credits', 'Credits'),
                ('debits', 'Debits'),
                ('refunds', 'Refunds'),
                ('failed', 'Failed'),
              ]) ...[
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: _filter == entry.$1,
                  onSelected: (_) => setState(() => _filter = entry.$1),
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
            title: 'No transactions found',
            message: 'No wallet activity matches the current filters.',
          )
        else
          for (var index = 0; index < rows.length; index++) ...[
            _TransactionTile(transaction: rows[index]),
            if (index != rows.length - 1)
              const SizedBox(height: B2BSpacing.sm),
          ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finance Ledger', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: B2BSpacing.xxs),
                Text(
                  'Track every B2B wallet movement from one workspace.',
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

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.wallet,
    required this.balance,
    required this.netMovement,
    required this.onTopUp,
  });

  final WalletData wallet;
  final String balance;
  final String netMovement;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(B2BSpacing.xl),
        decoration: BoxDecoration(
          gradient: B2BGradients.primary,
          borderRadius: BorderRadius.circular(B2BRadius.xl),
          boxShadow: B2BShadows.elevated,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AVAILABLE WALLET',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
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
              ),
            ),
            const SizedBox(height: B2BSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net movement',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        netMovement,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onTopUp,
                  icon: const Icon(Icons.add_card_rounded),
                  label: const Text('Top up'),
                ),
              ],
            ),
          ],
        ),
      );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final positive = transaction.isCredit;
    final color = positive ? AppColors.success : AppColors.danger;
    final sign = positive ? '+' : '-';
    final title = transaction.description.isEmpty
        ? _titleCase(transaction.type)
        : transaction.description;
    final meta = [
      if (transaction.orderNumber.isNotEmpty) transaction.orderNumber,
      if (transaction.reference.isNotEmpty) transaction.reference,
      if (transaction.provider.isNotEmpty) transaction.provider,
    ].join(' · ');
    final date = transaction.createdAt == null
        ? transaction.status
        : DateFormat('dd MMM yyyy, HH:mm')
            .format(transaction.createdAt!.toLocal());

    return B2BSurface(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(B2BRadius.md),
            ),
            child: Icon(
              positive ? Icons.north_east_rounded : Icons.south_west_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 3),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: B2BSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${transaction.currency} ${transaction.absoluteAmount.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                _titleCase(transaction.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner();
  @override
  Widget build(BuildContext context) => B2BSurface(
        showShadow: false,
        backgroundColor: AppColors.warning.withValues(alpha: .1),
        borderColor: AppColors.warning.withValues(alpha: .35),
        child: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.warning),
            SizedBox(width: B2BSpacing.sm),
            Expanded(
              child: Text(
                'Could not refresh. Showing the last available finance data.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

String _titleCase(String value) {
  final clean = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (clean.isEmpty) return 'Transaction';
  return clean
      .split(' ')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}
