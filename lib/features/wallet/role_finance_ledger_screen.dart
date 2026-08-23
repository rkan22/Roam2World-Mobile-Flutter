import 'package:flutter/material.dart';

import '../../shared/widgets/r2w_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/routing/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../auth/auth_repository.dart';
import '../dashboard/dashboard_topup_sheet.dart';
import 'wallet_data.dart';
import 'wallet_repository.dart';
import 'wallet_request.dart';
import 'wallet_screen.dart';

class RoleFinanceLedgerScreen extends StatefulWidget {
  const RoleFinanceLedgerScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<RoleFinanceLedgerScreen> createState() =>
      _RoleFinanceLedgerScreenState();
}

class _RoleFinanceLedgerScreenState extends State<RoleFinanceLedgerScreen> {
  late final AuthRepository _authRepository;
  final _repository = WalletRepository();
  final Map<String, TextEditingController> _allocationControllers = {};

  static const _providerLabels = <String, String>{
    'airhub': 'Vodafone',
    // Legacy backend allocation key used for manually fulfilled orders.
    'movistar': 'Manual Fulfillment',
    'worldmove': 'Orange Europe',
    'flexnet': 'Orange Big Data',
    'tgt': 'Orange Balkans',
  };

  bool _isHiddenProviderKey(String key) {
    final normalized = key.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return normalized == 'esimcard';
  }

  List<String> get _providerKeys {
    final backendKeys =
        _allocation?.allocations.keys
            .where((key) => !_isHiddenProviderKey(key))
            .toList() ??
        const <String>[];

    return backendKeys.isNotEmpty
        ? backendKeys
        : _providerLabels.keys
              .where((key) => !_isHiddenProviderKey(key))
              .toList();
  }

  String _providerLabel(String key) {
    final normalized = key.trim().toLowerCase();
    final knownLabel = _providerLabels[normalized];
    if (knownLabel != null) return knownLabel;

    final spaced = key
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .trim();

    if (spaced.isEmpty) return 'Provider';

    return spaced
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  AppRole? _role;
  WalletData? _wallet;
  ProviderAllocationData? _allocation;
  List<WalletRequest> _requests = const [];
  bool _loading = true;
  bool _savingAllocation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _allocationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _authRepository.readStoredProfile();
      final role = parseAppRole(profile?.role);
      if (role == AppRole.admin ||
          role == AppRole.client ||
          role == AppRole.publicUser) {
        if (!mounted) return;
        setState(() {
          _role = role;
          _loading = false;
        });
        return;
      }

      final results = await Future.wait([
        _repository.fetchWallet(forceRefresh: forceRefresh),
        _repository.fetchProviderAllocations(),
        _repository.fetchTopUpRequests(),
      ]);
      if (!mounted) return;
      final wallet = results[0] as WalletData;
      final allocation = results[1] as ProviderAllocationData;
      final requests = results[2] as List<WalletRequest>;
      _syncAllocationControllers(allocation);
      setState(() {
        _role = role;
        _wallet = wallet;
        _allocation = allocation;
        _requests = requests;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Finance ledger could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncAllocationControllers(ProviderAllocationData allocation) {
    final keys = allocation.allocations.isNotEmpty
        ? allocation.allocations.keys.where((key) => !_isHiddenProviderKey(key))
        : _providerLabels.keys.where((key) => !_isHiddenProviderKey(key));

    for (final key in keys) {
      final controller = _allocationControllers.putIfAbsent(
        key,
        () => TextEditingController(),
      );
      controller.text = (allocation.allocations[key] ?? 0).toStringAsFixed(2);
    }
  }

  Map<String, double>? _currentAllocations() {
    // Hidden legacy providers are preserved in the payload so an existing
    // allocation cannot be deleted accidentally while the provider is
    // removed from the mobile interface.
    final values = <String, double>{...?_allocation?.allocations};

    for (final key in _providerKeys) {
      final value = double.tryParse(
        _allocationControllers[key]?.text.trim() ?? '',
      );
      if (value == null || value < 0) return null;
      values[key] = value;
    }
    return values;
  }

  Future<void> _saveAllocations() async {
    final wallet = _wallet;
    final values = _currentAllocations();
    if (wallet == null || values == null) {
      _message('Enter valid provider allocation amounts.');
      return;
    }
    final total = values.values.fold<double>(0, (sum, value) => sum + value);
    if (total > wallet.availableAmount + .001) {
      _message(
        'Provider allocations cannot exceed the available wallet balance.',
      );
      return;
    }

    setState(() => _savingAllocation = true);
    try {
      final saved = await _repository.saveProviderAllocations(values);
      if (!mounted) return;
      _syncAllocationControllers(saved);
      setState(() => _allocation = saved);
      _message('Provider allocation saved.');
      await _load(forceRefresh: true);
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('Provider allocation could not be saved.');
    } finally {
      if (mounted) setState(() => _savingAllocation = false);
    }
  }

  Future<void> _showTopUpRequest() async {
    final wallet = _wallet;
    if (wallet == null) return;

    final submitted = await showDashboardTopUpSheet(
      context,
      currency: wallet.currency,
      repository: _repository,
    );

    if (submitted == true && mounted) {
      _message('Balance request created.');
      await _load(forceRefresh: true);
    }
  }

  void _message(String value) {
    R2WToast.info(context, value);
  }

  String _money(double value, String currency) =>
      NumberFormat.currency(name: currency, symbol: '$currency ').format(value);

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    if (role == AppRole.admin ||
        role == AppRole.client ||
        role == AppRole.publicUser) {
      return const WalletScreen();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        title: const Text('Finance Ledger'),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
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
            if (_loading && _wallet == null)
              const ContentLoadingState(label: 'Loading finance ledger...')
            else if (_error != null && _wallet == null)
              ContentErrorState(
                message: _error!,
                onRetry: () => _load(forceRefresh: true),
              )
            else if (_wallet != null) ...[
              _WalletHero(
                wallet: _wallet!,
                money: _money,
                onRequestBalance: _wallet!.canRequestTopUp
                    ? _showTopUpRequest
                    : null,
              ),
              const SizedBox(height: B2BSpacing.lg),
              _providerAllocationSection(_wallet!, _allocation),
              const SizedBox(height: B2BSpacing.lg),
              _fundingRequestsSection(_wallet!),
              const SizedBox(height: B2BSpacing.lg),
              _transactionsSection(_wallet!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _providerAllocationSection(
    WalletData wallet,
    ProviderAllocationData? allocation,
  ) {
    final values = _currentAllocations() ?? const <String, double>{};
    final allocated = values.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final available = (wallet.availableAmount - allocated)
        .clamp(0.0, double.infinity)
        .toDouble();
    final invalid = allocated > wallet.availableAmount + .001;
    final progress = wallet.availableAmount <= 0
        ? 0.0
        : (allocated / wallet.availableAmount).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider distribution',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Split funds already available in your wallet into provider credit limits.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: B2BSpacing.sm),
        B2BSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: B2BSpacing.md,
                runSpacing: B2BSpacing.xs,
                children: [
                  _SummaryValue(
                    label: 'Wallet',
                    value: _money(wallet.availableAmount, wallet.currency),
                  ),
                  _SummaryValue(
                    label: 'Allocated',
                    value: _money(allocated, wallet.currency),
                    danger: invalid,
                  ),
                  _SummaryValue(
                    label: 'Available',
                    value: _money(available, wallet.currency),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.md),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: B2BSpacing.md),
              for (final key in _providerKeys) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _providerLabel(key),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: B2BSpacing.sm),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _allocationControllers[key],
                        enabled: !_savingAllocation && allocation != null,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.right,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixText: '${wallet.currency} ',
                        ),
                      ),
                    ),
                  ],
                ),
                if (key != _providerKeys.last)
                  const SizedBox(height: B2BSpacing.sm),
              ],
              const SizedBox(height: B2BSpacing.md),
              if (invalid)
                const Text(
                  'Allocated provider credit is higher than the wallet balance.',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: allocation == null || invalid || _savingAllocation
                      ? null
                      : _saveAllocations,
                  icon: _savingAllocation
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _savingAllocation ? 'Saving...' : 'Save provider credits',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fundingRequestsSection(WalletData wallet) {
    final pending = _requests.where((item) => item.isPending).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Funding requests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (wallet.canRequestTopUp)
              TextButton.icon(
                onPressed: _showTopUpRequest,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Request'),
              ),
          ],
        ),
        const SizedBox(height: B2BSpacing.sm),
        if (pending.isEmpty)
          const B2BSurface(child: Text('No pending funding requests.'))
        else
          for (final request in pending.take(4)) ...[
            B2BSurface(
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.warning),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _money(request.amount, request.currency),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          request.status,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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

  Widget _transactionsSection(WalletData wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent transactions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: B2BSpacing.sm),
        if (wallet.transactions.isEmpty)
          const B2BSurface(child: Text('No wallet transactions yet.'))
        else
          for (final transaction in wallet.transactions.take(20)) ...[
            B2BSurface(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: transaction.isCredit
                        ? AppColors.successSoft
                        : AppColors.dangerSoft,
                    child: Icon(
                      transaction.isCredit
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: transaction.isCredit
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description.isEmpty
                              ? transaction.type
                              : transaction.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transaction.createdAt == null
                              ? transaction.status
                              : DateFormat(
                                  'dd MMM yyyy, HH:mm',
                                ).format(transaction.createdAt!.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Text(
                    '${transaction.isCredit ? '+' : '-'}${_money(transaction.displayAmount, transaction.currency)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: transaction.isCredit
                          ? AppColors.success
                          : AppColors.danger,
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

class _WalletHero extends StatelessWidget {
  const _WalletHero({
    required this.wallet,
    required this.money,
    this.onRequestBalance,
  });

  final WalletData wallet;
  final String Function(double, String) money;
  final VoidCallback? onRequestBalance;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(B2BSpacing.xl),
    decoration: BoxDecoration(
      color: const Color(0xFF020817),
      borderRadius: BorderRadius.circular(B2BRadius.xl),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AVAILABLE WALLET BALANCE',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: B2BSpacing.xs),
        Text(
          money(wallet.availableAmount, wallet.currency),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: B2BSpacing.sm),
        const Text(
          'Available funds can be distributed across approved providers.',
          style: TextStyle(color: Colors.white70),
        ),
        if (onRequestBalance != null) ...[
          const SizedBox(height: B2BSpacing.lg),
          FilledButton.icon(
            onPressed: onRequestBalance,
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Request balance'),
          ),
        ],
      ],
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    this.danger = false,
  });

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: danger ? AppColors.danger : null,
        ),
      ),
    ],
  );
}
