import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'dealer_network_data.dart';
import 'dealer_network_repository.dart';

class DealerNetworkScreen extends StatefulWidget {
  const DealerNetworkScreen({super.key});

  @override
  State<DealerNetworkScreen> createState() => _DealerNetworkScreenState();
}

class _DealerNetworkScreenState extends State<DealerNetworkScreen> {
  final _repository = DealerNetworkRepository();
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  DealerNetworkData? _data;
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final result = await _repository.fetchNetwork();
      if (mounted) setState(() => _data = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Dealer network could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DealerSummary> get _visibleDealers {
    final data = _data;
    if (data == null) return const [];
    final query = _searchController.text.trim().toLowerCase();
    return data.dealers.where((dealer) {
      final matchesQuery = query.isEmpty ||
          [dealer.name, dealer.email, dealer.phone]
              .any((value) => value.toLowerCase().contains(query));
      final matchesStatus = switch (_filter) {
        1 => dealer.isActive,
        2 => !dealer.isActive,
        _ => true,
      };
      return matchesQuery && matchesStatus;
    }).toList();
  }

  Future<void> _approve(DealerFundingRequest request) async {
    try {
      await _repository.approveRequest(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.dealerName} funding request approved.')),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _showTransfer(DealerSummary dealer) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    bool credit = true;
    bool submitting = false;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dealer wallet', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: B2BSpacing.xs),
              Text('${dealer.name} · ${dealer.currency} ${dealer.currentBalance.toStringAsFixed(2)}'),
              const SizedBox(height: B2BSpacing.lg),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Credit'), icon: Icon(Icons.add_rounded)),
                  ButtonSegment(value: false, label: Text('Debit'), icon: Icon(Icons.remove_rounded)),
                ],
                selected: {credit},
                onSelectionChanged: submitting
                    ? null
                    : (value) => setSheetState(() => credit = value.first),
              ),
              const SizedBox(height: B2BSpacing.md),
              TextField(
                controller: amount,
                enabled: !submitting,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount', prefixText: '${dealer.currency} '),
              ),
              const SizedBox(height: B2BSpacing.md),
              TextField(
                controller: note,
                enabled: !submitting,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              if (error != null) ...[
                const SizedBox(height: B2BSpacing.sm),
                Text(
                  error!,
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: B2BSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final value = double.tryParse(amount.text.trim());
                          if (value == null || value <= 0) {
                            setSheetState(() => error = 'Enter a valid amount.');
                            return;
                          }
                          setSheetState(() {
                            submitting = true;
                            error = null;
                          });
                          try {
                            await _repository.transfer(
                              dealerId: dealer.id,
                              amount: value,
                              credit: credit,
                              note: note.text,
                            );
                            if (!mounted || !sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            await _load();
                          } on ApiException catch (e) {
                            setSheetState(() => error = e.message);
                          } finally {
                            if (sheetContext.mounted) {
                              setSheetState(() => submitting = false);
                            }
                          }
                        },
                  child: Text(submitting ? 'Processing...' : credit ? 'Credit dealer' : 'Debit dealer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    amount.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final visible = _visibleDealers;
    final active = data?.dealers.where((item) => item.isActive).length ?? 0;
    final networkBalance = data?.dealers.fold<double>(
          0,
          (sum, item) => sum + item.currentBalance,
        ) ??
        0;
    final currency = data?.dealers.isNotEmpty == true ? data!.dealers.first.currency : 'USD';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Dealers'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.xs,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            Text('Dealer network', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Manage dealer exposure, funding requests and wallet balances.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading dealers...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              Row(
                children: [
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Dealers',
                      value: '${data.dealers.length}',
                      icon: Icons.storefront_outlined,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Active',
                      value: '$active',
                      icon: Icons.verified_user_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Network balance',
                      value: '$currency ${networkBalance.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Pending approvals',
                      value: '${data.pendingRequests.length}',
                      icon: Icons.pending_actions_outlined,
                    ),
                  ),
                ],
              ),
              if (data.pendingRequests.isNotEmpty) ...[
                const SizedBox(height: B2BSpacing.lg),
                Text('Funding requests', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: B2BSpacing.sm),
                for (final request in data.pendingRequests) ...[
                  B2BSurface(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(request.dealerName, style: const TextStyle(fontWeight: FontWeight.w900)),
                              if (request.dealerEmail.isNotEmpty)
                                Text(
                                  request.dealerEmail,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              if (request.note.isNotEmpty)
                                Text(
                                  request.note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: B2BSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${request.currency} ${request.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: B2BSpacing.xs),
                            FilledButton.tonal(
                              onPressed: () => _approve(request),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                ],
              ],
              const SizedBox(height: B2BSpacing.lg),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search dealer, email or phone',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: B2BSpacing.sm),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(width: B2BSpacing.xs),
                  itemBuilder: (context, index) => ChoiceChip(
                    label: Text(const ['All', 'Active', 'Suspended'][index]),
                    selected: _filter == index,
                    onSelected: (_) => setState(() => _filter = index),
                  ),
                ),
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (visible.isEmpty)
                const ContentEmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No dealers found',
                  message: 'Try another search or status filter.',
                )
              else
                for (final dealer in visible) ...[
                  B2BSurface(
                    onTap: () => _showTransfer(dealer),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(B2BRadius.md),
                              ),
                              child: Text(
                                _initials(dealer.name),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: B2BSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dealer.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  if (dealer.email.isNotEmpty)
                                    Text(
                                      dealer.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            _Status(active: dealer.isActive),
                          ],
                        ),
                        const SizedBox(height: B2BSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: B2BSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Available',
                                value: '${dealer.currency} ${dealer.currentBalance.toStringAsFixed(2)}',
                              ),
                            ),
                            Expanded(
                              child: _Metric(label: 'Clients', value: '${dealer.totalClients}'),
                            ),
                            Expanded(
                              child: _Metric(
                                label: 'Orders',
                                value: '${dealer.totalOrders}',
                                alignEnd: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.alignEnd = false});
  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      );
}

class _Status extends StatelessWidget {
  const _Status({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(B2BRadius.pill),
      ),
      child: Text(
        active ? 'Active' : 'Suspended',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2);
  return parts.isEmpty ? 'D' : parts.map((part) => part[0].toUpperCase()).join();
}
