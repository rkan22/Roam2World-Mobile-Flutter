import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'customers_repository.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repository = CustomersRepository();
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  CustomerDirectory? _directory;
  _CustomerFilter _filter = _CustomerFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final directory = await _repository.fetchCustomers();
      if (!mounted) return;
      setState(() => _directory = directory);
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

  List<CustomerDirectoryItem> get _visibleCustomers {
    final customers = _directory?.customers ?? const <CustomerDirectoryItem>[];
    final query = _searchController.text.trim().toLowerCase();
    return customers.where((customer) {
      final matchesFilter = switch (_filter) {
        _CustomerFilter.all => true,
        _CustomerFilter.active => _statusOf(customer) == 'active',
        _CustomerFilter.pending => _statusOf(customer) == 'pending',
        _CustomerFilter.inactive => _statusOf(customer) == 'inactive',
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.phoneNumber.toLowerCase().contains(query) ||
          customer.currentPlan.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = _directory?.customers ?? const <CustomerDirectoryItem>[];
    final activeClients = customers.where((item) => _statusOf(item) == 'active').length;
    final pendingClients = customers.where((item) => _statusOf(item) == 'pending').length;
    final activeEsims = customers.fold<int>(0, (sum, item) => sum + item.activeEsims);
    final visible = _visibleCustomers;

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
              if (!_loading && _error == null) ...[
                _KpiGrid(
                  totalClients: _directory?.count ?? customers.length,
                  activeClients: activeClients,
                  activeEsims: activeEsims,
                  pendingClients: pendingClients,
                ),
                const SizedBox(height: B2BSpacing.lg),
                _SearchField(controller: _searchController),
                const SizedBox(height: B2BSpacing.sm),
                _FilterBar(
                  selected: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: B2BSpacing.lg),
              ],
              if (_loading)
                const ContentLoadingState(label: 'Loading customers...')
              else if (_error != null)
                ContentErrorState(message: _error!, onRetry: _load)
              else if (visible.isEmpty)
                ContentEmptyState(
                  icon: Icons.groups_outlined,
                  title: customers.isEmpty ? 'No customers yet' : 'No matching customers',
                  message: customers.isEmpty
                      ? 'No customer records were returned for this account.'
                      : 'Try another search or status filter.',
                  actionLabel: customers.isEmpty ? 'Refresh' : 'Show all',
                  onAction: customers.isEmpty
                      ? _load
                      : () {
                          _searchController.clear();
                          setState(() => _filter = _CustomerFilter.all);
                        },
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${visible.length} customer${visible.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/packages'),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('New order'),
                    ),
                  ],
                ),
                const SizedBox(height: B2BSpacing.sm),
                for (final customer in visible) ...[
                  _CustomerCard(
                    customer: customer,
                    onView: () => _showCustomer(customer),
                    onOrder: () => context.go('/packages'),
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomer(CustomerDirectoryItem customer) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Email', value: _orDash(customer.email)),
              _DetailRow(label: 'Phone', value: _orDash(customer.phoneNumber)),
              _DetailRow(label: 'Status', value: _statusOf(customer)),
              _DetailRow(label: 'Current plan', value: _orDash(customer.currentPlan)),
              _DetailRow(label: 'Total orders', value: '${customer.totalOrders}'),
              _DetailRow(label: 'Total spend', value: _money(customer.totalSpent)),
              _DetailRow(label: 'eSIM / SIM', value: '${customer.activeEsims} active · ${customer.totalEsims} total'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go('/packages');
                  },
                  icon: const Icon(Icons.sim_card_outlined),
                  label: const Text('Create order'),
                ),
              ),
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
  Widget build(BuildContext context) => Row(
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
                      ),
                ),
                Text(
                  'Client plans, eSIM activity and spend.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.totalClients,
    required this.activeClients,
    required this.activeEsims,
    required this.pendingClients,
  });

  final int totalClients;
  final int activeClients;
  final int activeEsims;
  final int pendingClients;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: B2BSpacing.sm,
        crossAxisSpacing: B2BSpacing.sm,
        childAspectRatio: 2.25,
        children: [
          _KpiCard(
            label: 'Total clients',
            value: '$totalClients',
            icon: Icons.groups_outlined,
            color: const Color(0xFF2563EB),
            soft: const Color(0xFFEFF6FF),
          ),
          _KpiCard(
            label: 'Active clients',
            value: '$activeClients',
            icon: Icons.person_outline_rounded,
            color: AppColors.success,
            soft: AppColors.successSoft,
          ),
          _KpiCard(
            label: 'Active eSIM / SIM',
            value: '$activeEsims',
            icon: Icons.sim_card_outlined,
            color: AppColors.violet,
            soft: const Color(0xFFF3EEFF),
          ),
          _KpiCard(
            label: 'Pending activation',
            value: '$pendingClients',
            icon: Icons.pending_actions_outlined,
            color: AppColors.orange,
            soft: const Color(0xFFFFF2E8),
          ),
        ],
      );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.soft,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) => B2BSurface(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search name, email, phone or plan',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      );
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _CustomerFilter selected;
  final ValueChanged<_CustomerFilter> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in _CustomerFilter.values) ...[
              ChoiceChip(
                label: Text(filter.label),
                selected: selected == filter,
                onSelected: (_) => onChanged(filter),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      );
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onView,
    required this.onOrder,
  });

  final CustomerDirectoryItem customer;
  final VoidCallback onView;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(customer);
    final statusColor = switch (status) {
      'active' => AppColors.success,
      'pending' => AppColors.orange,
      'inactive' => AppColors.textSecondary,
      _ => AppColors.textSecondary,
    };
    final statusSoft = switch (status) {
      'active' => AppColors.successSoft,
      'pending' => const Color(0xFFFFF2E8),
      _ => const Color(0xFFF1F5F9),
    };

    return B2BSurface(
      padding: const EdgeInsets.all(B2BSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _initials(customer.name),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    if (customer.email.isNotEmpty)
                      _ContactLine(icon: Icons.mail_outline_rounded, text: customer.email),
                    if (customer.phoneNumber.isNotEmpty)
                      _ContactLine(icon: Icons.phone_outlined, text: customer.phoneNumber),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Metric(
                  label: 'Current plan',
                  value: customer.currentPlan.isEmpty ? 'No assigned plan' : customer.currentPlan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'eSIM / SIM',
                  value: '${customer.activeEsims} active · ${customer.totalEsims} total',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Spend',
                  value: _money(customer.totalSpent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 17),
                label: const Text('View'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOrder,
                  icon: const Icon(Icons.sim_card_outlined, size: 17),
                  label: const Text('Order'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

enum _CustomerFilter { all, active, pending, inactive }

extension on _CustomerFilter {
  String get label => switch (this) {
        _CustomerFilter.all => 'All',
        _CustomerFilter.active => 'Active',
        _CustomerFilter.pending => 'Pending',
        _CustomerFilter.inactive => 'Inactive',
      };
}

String _statusOf(CustomerDirectoryItem customer) {
  final status = customer.status.trim().toLowerCase();
  if (status.contains('pending')) return 'pending';
  if (status.contains('inactive') ||
      status.contains('suspend') ||
      status.contains('block') ||
      customer.isActive == false) {
    return 'inactive';
  }
  if (status.contains('active') || customer.isActive == true) return 'active';
  return status.isEmpty ? 'unknown' : status;
}

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _money(double value) => 'USD ${value.toStringAsFixed(2)}';
String _orDash(String value) => value.trim().isEmpty ? 'Not provided' : value.trim();
