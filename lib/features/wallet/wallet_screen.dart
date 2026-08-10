import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'wallet_data.dart';
import 'wallet_repository.dart';
import 'widgets/wallet_adaptive_sections.dart';

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
  int _selectedFilter = 0;

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
      setState(() => _error = 'Wallet could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(double value, String currency) {
    return NumberFormat.currency(name: currency, symbol: '$currency ').format(value);
  }

  List<WalletTransaction> _visibleTransactions(WalletData wallet) {
    return switch (_selectedFilter) {
      1 => wallet.transactions.where((item) => item.isCredit).toList(),
      2 => wallet.transactions.where((item) => !item.isCredit).toList(),
      _ => wallet.transactions,
    };
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
              await _load(forceRefresh: true);
            } on ApiException catch (error) {
              setSheetState(() => submitError = error.message);
            } catch (_) {
              setSheetState(() => submitError = 'Top-up request could not be created.');
            } finally {
              if (sheetContext.mounted) setSheetState(() => submitting = false);
            }
          }

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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(B2BRadius.md),
                    ),
                    child: const Icon(Icons.add_card_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(height: B2BSpacing.md),
                  Text(
                    'Request wallet top-up',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  const Text(
                    'Create a funding request for your business wallet. Your available funds update after approval.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: B2BSpacing.lg),
                  TextFormField(
                    controller: amountController,
                    enabled: !submitting,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Top-up amount',
                      prefixText: '${wallet.currency} ',
                      prefixIcon: const Icon(Icons.payments_outlined),
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
                    decoration: const InputDecoration(
                      labelText: 'Reference note (optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
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
                  FilledButton.icon(
                    onPressed: submitting ? null : submit,
                    icon: submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                    label: Text(submitting ? 'Sending request...' : 'Send top-up request'),
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
              _Header(
                onBack: () => context.pop(),
                onRefresh: () => _load(forceRefresh: true),
              ),
              if (_showingStaleData) ...[
                const SizedBox(height: B2BSpacing.md),
                const _StaleDataBanner(),
              ],
              const SizedBox(height: B2BSpacing.lg),
              if (_loading)
                const ContentLoadingState(label: 'Loading wallet...')
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
    final transactions = _visibleTransactions(wallet);
    return WalletAdaptiveSections(
      summary: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceHero(
            wallet: wallet,
            amount: _money(wallet.availableAmount, wallet.currency),
            onTopUp: () => _showTopUpRequest(wallet),
          ),
          const SizedBox(height: B2BSpacing.md),
          Row(
            children: [
              Expanded(
                child: B2BMetricCard(
                  label: wallet.isDealer ? 'Current balance' : 'Current credit',
                  value: _money(wallet.currentAmount, wallet.currency),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: B2BMetricCard(
                  label: wallet.secondaryLabel,
                  value: _money(wallet.secondaryAmount, wallet.currency),
                  icon: wallet.isDealer
                      ? Icons.trending_down_rounded
                      : Icons.credit_score_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
      transactions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Recent transactions',
            subtitle: 'Your latest wallet credits and debits',
          ),
          const SizedBox(height: B2BSpacing.sm),
          _TransactionFilters(
            selectedIndex: _selectedFilter,
            onSelected: (index) => setState(() => _selectedFilter = index),
          ),
          const SizedBox(height: B2BSpacing.md),
          if (transactions.isEmpty)
            const ContentEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions found',
              message: 'Wallet activity matching this filter will appear here.',
            )
          else
            for (var index = 0; index < transactions.length; index++) ...[
              _TransactionTile(transaction: transactions[index]),
              if (index != transactions.length - 1)
                const SizedBox(height: B2BSpacing.sm),
            ],
        ],
      ),
    );
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
              Text('Wallet', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: B2BSpacing.xxs),
              Text(
                'Business funds & settlement activity',
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

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.wallet,
    required this.amount,
    required this.onTopUp,
  });

  final WalletData wallet;
  final String amount;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: B2BGradients.primary,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        boxShadow: B2BShadows.hero,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        child: Stack(
          children: [
            Positioned(
              right: -45,
              top: -55,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
            ),
            Positioned(
              left: -75,
              bottom: -95,
              child: Container(
                width: 230,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(B2BRadius.full),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .07),
                    width: 26,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(B2BSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: B2BSpacing.sm,
                          vertical: B2BSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(B2BRadius.pill),
                        ),
                        child: Text(
                          wallet.role.isEmpty
                              ? 'BUSINESS WALLET'
                              : wallet.role.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(B2BRadius.md),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: B2BSpacing.xl),
                  Text(
                    wallet.isDealer ? 'Available balance' : 'Available credit',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  Text(
                    wallet.isDealer
                        ? 'Available for new orders and settlements'
                        : 'Available credit for new eSIM orders',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: B2BSpacing.xl),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: onTopUp,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add funds'),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: B2BSpacing.sm,
                          vertical: B2BSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(B2BRadius.pill),
                        ),
                        child: Text(
                          wallet.currency,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: B2BSpacing.xxs),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _TransactionFilters extends StatelessWidget {
  const _TransactionFilters({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['All', 'Credits', 'Debits'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: B2BSpacing.xs),
        itemBuilder: (context, index) => ChoiceChip(
          label: Text(labels[index]),
          selected: selectedIndex == index,
          onSelected: (_) => onSelected(index),
        ),
      ),
    );
  }
}

class _StaleDataBanner extends StatelessWidget {
  const _StaleDataBanner();

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
                'Could not refresh. Showing the last available wallet data.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
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
    final date = transaction.createdAt == null
        ? transaction.status
        : DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt!.toLocal());
    final title = transaction.description.isEmpty
        ? _titleCase(transaction.type)
        : transaction.description;

    return B2BSurface(
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(B2BRadius.md),
            ),
            child: Icon(
              positive ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: B2BSpacing.xxs),
                Text(
                  date.isEmpty ? 'Recently' : date,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: B2BSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              if (transaction.status.isNotEmpty) ...[
                const SizedBox(height: B2BSpacing.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(B2BRadius.pill),
                  ),
                  child: Text(
                    _titleCase(transaction.status),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String _titleCase(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) return 'Transaction';
  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}
