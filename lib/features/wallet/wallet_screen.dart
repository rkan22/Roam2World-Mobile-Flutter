import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/content_state.dart';
import 'wallet_data.dart';
import 'wallet_repository.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _repository = WalletRepository();
  bool _loading = true;
  bool _showingStaleData = false;
  String? _error;
  WalletData? _wallet;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = _wallet == null;
      _error = null;
    });
    try {
      final wallet = await _repository.fetchWallet(
        forceRefresh: forceRefresh,
      );
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
      setState(() => _error = 'Wallet could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(double value, String currency) {
    return NumberFormat.currency(name: currency, symbol: '$currency ').format(value);
  }

  Future<void> _showTopUpRequest(WalletData wallet) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var submitting = false;
    String? submitError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> submit() async {
            if (!(formKey.currentState?.validate() ?? false) || submitting) return;
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
                    '${request.currency} ${request.amount.toStringAsFixed(2)} top-up request created. Status: ${request.status}.',
                  ),
                ),
              );
            } on ApiException catch (error) {
              setSheetState(() => submitError = error.message);
            } catch (_) {
              setSheetState(() => submitError = 'Top-up request could not be created.');
            } finally {
              if (sheetContext.mounted) {
                setSheetState(() => submitting = false);
              }
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request wallet top-up', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'Your balance will change only after the request is approved.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: amountController,
                    enabled: !submitting,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Amount', prefixText: '${wallet.currency} '),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount <= 0) return 'Enter an amount greater than zero.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: noteController,
                    enabled: !submitting,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                  ),
                  if (submitError != null) ...[
                    const SizedBox(height: 12),
                    Text(submitError!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: submitting ? null : submit,
                    child: submitting
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Send request'),
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
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Wallet'),
        actions: [IconButton(onPressed: () => _load(forceRefresh: true), icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            if (_showingStaleData) ...[
              const _StaleDataBanner(),
              const SizedBox(height: 14),
            ],
            if (_loading)
              const ContentLoadingState(label: 'Loading wallet...')
            else if (_error != null && _wallet == null)
              ContentErrorState(message: _error!, onRetry: () => _load(forceRefresh: true))
            else if (_wallet != null)
              ..._content(_wallet!),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(WalletData wallet) {
    return [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.navy, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(wallet.isDealer ? 'Available balance' : 'Available credit', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(_money(wallet.availableAmount, wallet.currency), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _Metric(label: wallet.isDealer ? 'Current balance' : 'Current credit', value: _money(wallet.currentAmount, wallet.currency))),
                const SizedBox(width: 10),
                Expanded(child: _Metric(label: wallet.secondaryLabel, value: _money(wallet.secondaryAmount, wallet.currency))),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: () => _showTopUpRequest(wallet),
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Request top-up'),
      ),
      const SizedBox(height: 26),
      const Text('Recent transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      if (wallet.transactions.isEmpty)
        const ContentEmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions yet', message: 'Wallet activity will appear here.')
      else
        for (var index = 0; index < wallet.transactions.length; index++) ...[
          _TransactionTile(transaction: wallet.transactions[index]),
          if (index != wallet.transactions.length - 1) const SizedBox(height: 10),
        ],
    ];
  }
}

class _StaleDataBanner extends StatelessWidget {
  const _StaleDataBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: .4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 19, color: AppColors.warning),
            SizedBox(width: 10),
            Expanded(child: Text('Could not refresh. Showing the last available wallet data.', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ]),
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
    final date = transaction.createdAt == null ? transaction.status : DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt!.toLocal());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(height: 46, width: 46, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(15)), child: Icon(positive ? Icons.add_rounded : Icons.remove_rounded, color: color)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(transaction.description.isEmpty ? transaction.type : transaction.description, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        Text('$sign${transaction.currency} ${transaction.amount.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
