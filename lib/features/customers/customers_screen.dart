import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Customers'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search customer name',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 18),
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
                    : 'Try another customer name.',
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
                  const Text(
                    'Order customers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Text(
                    '${visibleCustomers.length} customers',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final customer in visibleCustomers) ...[
                _CustomerCard(customer: customer),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
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
      lastOrderAt: _latest(existing?.lastOrderAt, order.createdAt),
    );
  }
  final customers = grouped.values.toList();
  customers.sort((a, b) {
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
    required this.lastOrderAt,
  });

  final String name;
  final int orders;
  final DateTime? lastOrderAt;
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});
  final _CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    final parts = customer.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Created from live order history',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${customer.orders}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'orders',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
