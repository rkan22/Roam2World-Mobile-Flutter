import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../wallet/wallet_repository.dart';

Future<bool?> showDashboardTopUpSheet(
  BuildContext context, {
  required String currency,
  WalletRepository? repository,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DashboardTopUpSheet(
      currency: currency,
      repository: repository ?? WalletRepository(),
    ),
  );
}

class _DashboardTopUpSheet extends StatefulWidget {
  const _DashboardTopUpSheet({
    required this.currency,
    required this.repository,
  });

  final String currency;
  final WalletRepository repository;

  @override
  State<_DashboardTopUpSheet> createState() => _DashboardTopUpSheetState();
}

class _DashboardTopUpSheetState extends State<_DashboardTopUpSheet> {
  static const _quickAmounts = <double>[50, 100, 200, 500, 1000, 2000];

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  double? _selectedAmount;
  bool _submitting = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _amount {
    if (_selectedAmount != null) return _selectedAmount;
    final normalized = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid top-up amount.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.repository.createTopUpRequest(
        amount: amount,
        currency: widget.currency,
        note: _noteController.text,
      );
      if (!mounted) return;
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Top-up request could not be submitted.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = widget.currency.trim().isEmpty
        ? 'USD'
        : widget.currency.trim().toUpperCase();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 36),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top up wallet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a quick amount or enter a custom amount.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Quick amount',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final amount in _quickAmounts)
                  ChoiceChip(
                    label: Text('$currency ${amount.toStringAsFixed(0)}'),
                    selected: _selectedAmount == amount,
                    onSelected: _submitting
                        ? null
                        : (_) {
                            setState(() {
                              _selectedAmount = amount;
                              _amountController.clear();
                              _error = null;
                            });
                          },
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              enabled: !_submitting,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Custom amount',
                prefixText: '$currency ',
                hintText: '0.00',
              ),
              onChanged: (_) {
                if (_selectedAmount != null || _error != null) {
                  setState(() {
                    _selectedAmount = null;
                    _error = null;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              enabled: !_submitting,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add a note for this top-up request',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: .18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _submitting || _success ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _success ? AppColors.success : AppColors.navy,
                  foregroundColor: Colors.white,
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_success ? Icons.check_circle_rounded : Icons.add_rounded),
                label: Text(
                  _success
                      ? 'Request submitted'
                      : _submitting
                          ? 'Submitting...'
                          : 'Submit top-up request',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
