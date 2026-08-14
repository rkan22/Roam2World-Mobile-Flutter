import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../orders/order_history.dart';
import '../orders/orders_repository.dart';
import 'customers_repository.dart';
import 'widgets/customers_adaptive_grid.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repository = OrdersRepository();
  final _customersRepository = CustomersRepository();
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
      var directory = const CustomerDirectory(names: [], count: 0);
      try {
        directory = await _customersRepository.fetchCustomers();
      } catch (_) {
        // Orders still provide a useful customer fallback if the directory is
        // temporarily unavailable.
      }
      if (!mounted) return;
      setState(
        () => _customers = _aggregateCustomers(
          history.orders,
          directoryNames: directory.names,
        ),
      );
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

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/dashboard');
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              B2BSpacing.lg,
              B2BSpacing.md,
              B2BSpacing.lg,
              B2BSpacing.xxl,
            ),
            children: [
              _Header(onBack: _handleBack, onRefresh: _load),
              const SizedBox(height: B2BSpacing.lg),
              if (!_loading && _error == null && visibleCustomers.isNotEmpty)
                _CustomerOverview(
                  customerCount: visibleCustomers.length,
                  orderCount: totalOrders,
                  totalSpend: totalSpend,
                  currency: currency,
                  onNewSale: () => context.go('/packages'),
                ),
              if (!_loading && _error == null && visibleCustomers.isNotEmpty)
                const SizedBox(height: B2BSpacing.lg),
              _SearchField(controller: _searchController),
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
                      ? 'Customers are created automatically from completed and pending B2B orders.'
                      : 'Try another company or customer name.',
                  actionLabel: _customers.isEmpty
                      ? 'Create first sale'
                      : 'Clear search',
                  onAction: _customers.isEmpty
                      ? () => context.go('/packages')
                      : _searchController.clear,
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accounts',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: B2BSpacing.xxs),
                          Text(
                            '${visibleCustomers.length} customer${visibleCustomers.length == 1 ? '' : 's'} in this view',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/packages'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New sale'),
                    ),
                  ],
                ),
                const SizedBox(height: B2BSpacing.sm),
                CustomersAdaptiveGrid(
                  children: [
                    for (final customer in visibleCustomers)
                      _CustomerCard(
                        customer: customer,
                        onTap: () => context.go('/orders'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                'Customers',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
              ),
              const SizedBox(height: B2BSpacing.xxs),
              Text(
                'Customer activity and sales value in one workspace.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _CustomerOverview extends StatelessWidget {
  const _CustomerOverview({
    required this.customerCount,
    required this.orderCount,
    required this.totalSpend,
    required this.currency,
    required this.onNewSale,
  });

  final int customerCount;
  final int orderCount;
  final double totalSpend;
  final String currency;
  final VoidCallback onNewSale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return B2BSurface(
      padding: const EdgeInsets.all(B2BSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: B2BSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: B2BSpacing.xxs),
                    Text(
                      'Live totals from your customer order history',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onNewSale,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Sale'),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _OverviewValue(
                  label: 'Customers',
                  value: '$customerCount',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: _OverviewValue(
                  label: 'Orders',
                  value: '$orderCount',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: _OverviewValue(
                  label: 'Revenue',
                  value:
                      '${_currencySymbol(currency)}${totalSpend.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(B2BSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(B2BRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: B2BSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: B2BSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search customers',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: B2BSpacing.md,
          vertical: B2BSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(B2BRadius.lg),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(B2BRadius.lg),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(B2BRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

List<_CustomerSummary> _aggregateCustomers(
  List<MobileOrderSummary> orders, {
  List<String> directoryNames = const [],
}) {
  final grouped = <String, _CustomerSummary>{};
  for (final name in directoryNames) {
    grouped[name.toLowerCase()] = _CustomerSummary(
      name: name,
      orders: 0,
      totalSpend: 0,
      currency: 'USD',
      lastOrderAt: null,
    );
  }
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
  const _CustomerCard({required this.customer, required this.onTap});

  final _CustomerSummary customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(customer.name);
    final scheme = Theme.of(context).colorScheme;
    final symbol = _currencySymbol(customer.currency);
    return B2BSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(B2BSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: B2BSpacing.md),
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
                    Text(
                      customer.lastOrderAt == null
                          ? 'No recent activity'
                          : 'Last order ${_formatDate(customer.lastOrderAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _CustomerMetric(
                  label: 'Orders',
                  value: '${customer.orders}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              Container(
                height: 42,
                width: 1,
                color: scheme.outlineVariant,
                margin: const EdgeInsets.symmetric(horizontal: B2BSpacing.md),
              ),
              Expanded(
                child: _CustomerMetric(
                  label: 'Total spend',
                  value: '$symbol${customer.totalSpend.toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
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
    required this.icon,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: B2BSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: B2BSpacing.xs),
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

String _currencySymbol(String currency) {
  switch (currency.trim().toUpperCase()) {
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'TRY':
      return '₺';
    default:
      final normalized = currency.trim().toUpperCase();
      return normalized.isEmpty ? '' : '$normalized ';
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
