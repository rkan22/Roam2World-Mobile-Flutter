import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../orders/order_history.dart';
import '../orders/orders_repository.dart';
import 'customer_detail_screen.dart';
import 'widgets/customers_adaptive_grid.dart';

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
  String _statusFilter = 'all';

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
    return _customers.where((customer) {
      final matchesQuery = query.isEmpty || customer.name.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == 'all' || customer.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
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
    final currency = visibleCustomers.isEmpty ? 'USD' : visibleCustomers.first.currency;
    final activeCount = _customers.where((customer) => customer.status == 'active').length;
    final pendingCount = _customers.where((customer) => customer.status == 'pending').length;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client Management', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: B2BSpacing.xs),
                      Text(
                        'View customer order activity and create the next order from one mobile workspace.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: B2BSpacing.sm),
                FilledButton.icon(
                  onPressed: () => context.go('/packages'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Order'),
                ),
              ],
            ),
            const SizedBox(height: B2BSpacing.lg),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search customer name',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: B2BSpacing.sm),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _StatusChip(
                    label: 'All',
                    count: _customers.length,
                    selected: _statusFilter == 'all',
                    onTap: () => setState(() => _statusFilter = 'all'),
                  ),
                  const SizedBox(width: B2BSpacing.xs),
                  _StatusChip(
                    label: 'Active',
                    count: activeCount,
                    selected: _statusFilter == 'active',
                    onTap: () => setState(() => _statusFilter = 'active'),
                  ),
                  const SizedBox(width: B2BSpacing.xs),
                  _StatusChip(
                    label: 'Pending',
                    count: pendingCount,
                    selected: _statusFilter == 'pending',
                    onTap: () => setState(() => _statusFilter = 'pending'),
                  ),
                ],
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
                title: _customers.isEmpty ? 'No customers yet' : 'No matching customers',
                message: _customers.isEmpty
                    ? 'Customers will appear after their first order.'
                    : 'Try another name or status filter.',
                actionLabel: _customers.isEmpty ? 'Browse packages' : 'Clear filters',
                onAction: _customers.isEmpty
                    ? () => context.go('/packages')
                    : () {
                        _searchController.clear();
                        setState(() => _statusFilter = 'all');
                      },
              )
            else ...[
              Row(
                children: [
                  Text('Customers', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text(
                    '${visibleCustomers.length} results',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.sm),
              CustomersAdaptiveGrid(
                children: [
                  for (final customer in visibleCustomers)
                    _CustomerCard(
                      customer: customer,
                      onTap: () => context.push(
                        '/customers/detail',
                        extra: CustomerDetailArgs(
                          name: customer.name,
                          orders: customer.orders,
                          totalSpend: customer.totalSpend,
                          currency: customer.currency,
                          lastOrderAt: customer.lastOrderAt,
                          orderHistory: customer.orderHistory,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text('$label  $count'),
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
          Expanded(child: _OverviewValue(label: 'Customers', value: '$customerCount')),
          Container(width: 1, height: 44, color: Colors.white24),
          Expanded(child: _OverviewValue(label: 'Orders', value: '$orderCount')),
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
  final groupedOrders = <String, List<MobileOrderSummary>>{};
  for (final order in orders) {
    final name = order.customerName.trim();
    if (name.isEmpty) continue;
    groupedOrders.putIfAbsent(name.toLowerCase(), () => []).add(order);
  }

  final customers = groupedOrders.values.map((customerOrders) {
    customerOrders.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    final first = customerOrders.first;
    final totalSpend = customerOrders.fold<double>(0, (sum, order) => sum + order.amount);
    final hasPending = customerOrders.any((order) => _isPending(order.status));
    final hasCompleted = customerOrders.any((order) => _isCompleted(order.status));
    return _CustomerSummary(
      name: first.customerName.trim(),
      orders: customerOrders.length,
      totalSpend: totalSpend,
      currency: first.currency,
      lastOrderAt: customerOrders.map((order) => order.createdAt).whereType<DateTime>().fold<DateTime?>(
            null,
            (latest, date) => latest == null || date.isAfter(latest) ? date : latest,
          ),
      status: hasPending && !hasCompleted ? 'pending' : 'active',
      orderHistory: List.unmodifiable(customerOrders),
    );
  }).toList();

  customers.sort((a, b) {
    final left = a.lastOrderAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final right = b.lastOrderAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateCompare = right.compareTo(left);
    return dateCompare != 0 ? dateCompare : b.totalSpend.compareTo(a.totalSpend);
  });
  return customers;
}

class _CustomerSummary {
  const _CustomerSummary({
    required this.name,
    required this.orders,
    required this.totalSpend,
    required this.currency,
    required this.lastOrderAt,
    required this.status,
    required this.orderHistory,
  });

  final String name;
  final int orders;
  final double totalSpend;
  final String currency;
  final DateTime? lastOrderAt;
  final String status;
  final List<MobileOrderSummary> orderHistory;
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onTap});

  final _CustomerSummary customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(customer.name);
    final scheme = Theme.of(context).colorScheme;
    final pending = customer.status == 'pending';
    return B2BSurface(
      padding: const EdgeInsets.all(B2BSpacing.md),
      onTap: onTap,
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
                          decoration: BoxDecoration(
                            color: pending ? AppColors.warning : AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: B2BSpacing.xs),
                        Expanded(
                          child: Text(
                            '${pending ? 'Pending' : 'Active'} · ${_formatDate(customer.lastOrderAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: B2BSpacing.md),
          Row(
            children: [
              Expanded(child: _CustomerMetric(label: 'Orders', value: '${customer.orders}')),
              Expanded(
                child: _CustomerMetric(
                  label: 'Total spend',
                  value: '${customer.currency} ${customer.totalSpend.toStringAsFixed(2)}',
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
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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

bool _isCompleted(String status) => RegExp(r'complete|success|deliver|active', caseSensitive: false).hasMatch(status);
bool _isPending(String status) => RegExp(r'pending|process|provision|await', caseSensitive: false).hasMatch(status);

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _formatDate(DateTime? date) {
  if (date == null) return 'No recent activity';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
}
