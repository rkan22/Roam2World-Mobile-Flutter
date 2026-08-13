import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'dealer_network_data.dart';
import 'dealer_network_repository.dart';

class DealerManagementScreen extends StatefulWidget {
  const DealerManagementScreen({super.key});

  @override
  State<DealerManagementScreen> createState() => _DealerManagementScreenState();
}

class _DealerManagementScreenState extends State<DealerManagementScreen> {
  final _repository = DealerNetworkRepository();
  final _searchController = TextEditingController();
  DealerNetworkData? _data;
  bool _loading = true;
  String? _error;
  int _filter = 0;
  int? _busyDealerId;

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

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await _repository.fetchNetwork();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Dealer management could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DealerSummary> get _visibleDealers {
    final dealers = _data?.dealers ?? const <DealerSummary>[];
    final query = _searchController.text.trim().toLowerCase();
    return dealers.where((dealer) {
      final matchesQuery = query.isEmpty ||
          [dealer.name, dealer.email, dealer.phone]
              .any((value) => value.toLowerCase().contains(query));
      final matchesFilter = switch (_filter) {
        1 => dealer.isActive,
        2 => !dealer.isActive,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _toggleDealer(DealerSummary dealer) async {
    final suspend = dealer.isActive;
    String? reason;

    if (suspend) {
      reason = await _askSuspendReason(dealer);
      if (reason == null) return;
    }

    setState(() => _busyDealerId = dealer.id);
    try {
      await _repository.setDealerSuspended(
        dealer.id,
        suspended: suspend,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(suspend ? '${dealer.name} suspended.' : '${dealer.name} activated.')),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dealer status could not be updated.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyDealerId = null);
    }
  }

  Future<String?> _askSuspendReason(DealerSummary dealer) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Suspend ${dealer.name}?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Enter a reason for suspension',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleDealers;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Dealer Management'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.sm, B2BSpacing.lg, B2BSpacing.xxl),
          children: [
            Text('Manage dealers', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Review dealer status and activate or suspend accounts using the existing backend actions.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading dealers...')
            else if (_error != null && _data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else ...[
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
                  itemBuilder: (_, index) => ChoiceChip(
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(B2BSpacing.md),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: AppColors.primary,
                                child: Text(_initials(dealer.name)),
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
                          Row(
                            children: [
                              Expanded(child: _Metric(label: 'Balance', value: '${dealer.currency} ${dealer.currentBalance.toStringAsFixed(2)}')),
                              Expanded(child: _Metric(label: 'Clients', value: '${dealer.totalClients}')),
                              Expanded(child: _Metric(label: 'Orders', value: '${dealer.totalOrders}')),
                            ],
                          ),
                          const SizedBox(height: B2BSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busyDealerId == dealer.id ? null : () => _toggleDealer(dealer),
                              icon: _busyDealerId == dealer.id
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(dealer.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline),
                              label: Text(dealer.isActive ? 'Suspend dealer' : 'Activate dealer'),
                            ),
                          ),
                        ],
                      ),
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
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2);
  return parts.isEmpty ? 'D' : parts.map((part) => part[0].toUpperCase()).join();
}
