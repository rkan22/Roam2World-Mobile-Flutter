import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../orders/order_history.dart';
import '../orders/orders_repository.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repository = OrdersRepository();
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<_CustomerSummary> _customers = const [];

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
      _loading = true;
      _error = null;
    });
    try {
      final history = await _repository.fetchOrders();
      if (!mounted) return;
      setState(() => _customers = _aggregateCustomers(history.orders));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Customers could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_CustomerSummary> get _visibleCustomers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers
        .where((customer) => customer.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCustomers = _visibleCustomers;
    final totalOrders = visibleCustomers.fold<int>(
      0,
      (sum, customer) => sum + customer.orders,
    );
    final totalSpend = visibleCustomers.fold<double>(
      0,
      (sum, customer) => sum + customer.totalSpend,
    );
    final currency = visibleCustomers.isEmpty
        ? 'USD'
        : visibleCustomers.first.currency;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Customers'),
        actions: [
          IconButton.filledTonal(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: B2BSpacing.sm),
        ],
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
            Text(
              'Your business network',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            Text(
              'Track customer activity generated from live order history.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: B2BSpacing.lg),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search company or customer',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: B2BSpacing.md),
            if (!_loading && _error == null && visibleCustomers.isNotEmpty)
              _CustomerOverview(
                customerCount: visibleCustomers.length,
                orderCount: totalOrders,
                totalSpend: totalSpend,
                currency: currency,
              ),
            if (!_loading && _error == null && visibleCustomers.isNotEmpty)
              const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading customers...')
            else if (_error != null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (visibleCustomers.isEmpty)
              ContentEmptyState(
                icon: Icons.people_outline_rounded,
                title: _customers.isEmpty
                    ? 'No customers yet'
                    : 'No matching customers',
                message: _customers.isEmpty
                    ? 'Customers will appear after their first order.'
                    : 'Try another company or customer name.',
                actionLabel: _customers.isEmpty
                    ? 'Browse packages'
                    : 'Clear search',
                onAction: _customers.isEmpty
                    ? () => context.go('/packages')
                    : _searchController.clear,
              )
            else ...[
              Row(
                children: [
                  Text(
                    'Companies',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${visibleCustomers.length} results',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.sm),
              for (final customer in visibleCustomers) ...[
                _CustomerCard(customer: customer),
                const SizedBox(height: B2BSpacing.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerOverview extends StatelessWidget {
  const _CustomerOverview({
    required this.customerCount,
    required this.orderCount,
    required this.totalSpend,
    required this.currency,
  });

  final int customerCount;
  final int orderCount;
  final double totalSpend;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      backgroundColor: AppColors.navy,
      borderColor: AppColors.navy,
      padding: const EdgeInsets.all(B2BSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _OverviewValue(
              label: 'Customers',
              value: '$customerCount',
            ),
          ),
          Container(width: 1, height: 44, color: Colors.white24),
          Expanded(
            child: _OverviewValue(
              label: 'Orders',
              value: '$orderCount',
            ),
          ),
          Container(width: 1, height: 44, color: Colors.white24),
          Expanded(
            child: _OverviewValue(
              label: 'Volume',
              value: '$currency ${totalSpend.toStringAsFixed(0)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: B2BSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

List<_CustomerSummary> _aggregateCustomers(List<MobileOrderSummary> orders) {
  final grouped = <String, _CustomerSummary>{};
  for (final order in orders) {
    final name = order.customerName.trim();
    if (name.isEmpty) continue;
    final key = name.toLowerCase();
    final existing = grouped[key];
    grouped[key] = _CustomerSummary(
      name: name,
      orders: (existing?.orders ?? 0) + 1,
      totalSpend: (existing?.totalSpend ?? 0) + order.amount,
      currency: existing?.currency ?? order.currency,
      lastOrderAt: _latest(existing?.lastOrderAt, order.createdAt),
    );
  }
  final customers = grouped.values.toList();
  customers.sort((a, b) {
    final spendCompare = b.totalSpend.compareTo(a.totalSpend);
    if (spendCompare != 0) return spendCompare;
    final left = a.lastOrderAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final right = b.lastOrderAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return right.compareTo(left);
  });
  return customers;
}

DateTime? _latest(DateTime? first, DateTime? second) {
  if (first == null) return second;
  if (second == null) return first;
  return first.isAfter(second) ? first : second;
}

class _CustomerSummary {
  const _CustomerSummary({
    required this.name,
    required this.orders,
    required this.totalSpend,
    required this.currency,
    required this.lastOrderAt,
  });

  final String name;
  final int orders;
  final double totalSpend;
  final String currency;
  final DateTime? lastOrderAt;
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final _CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(customer.name);
    return B2BSurface(
      padding: const EdgeInsets.all(B2BSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: B2BGradients.primary,
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: B2BSpacing.xxs),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: B2BSpacing.xs),
                        Text(
                          'Active · ${_formatDate(customer.lastOrderAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: B2BSpacing.md),
          Row(
            children: [
              Expanded(
                child: _CustomerMetric(
                  label: 'Orders',
                  value: '${customer.orders}',
                ),
              ),
              Expanded(
                child: _CustomerMetric(
                  label: 'Total spend',
                  value:
                      '${customer.currency} ${customer.totalSpend.toStringAsFixed(2)}',
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerMetric extends StatelessWidget {
  const _CustomerMetric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: B2BSpacing.xxs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _formatDate(DateTime? date) {
  if (date == null) return 'No recent activity';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
}
