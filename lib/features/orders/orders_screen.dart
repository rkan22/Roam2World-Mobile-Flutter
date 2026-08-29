import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import '../../shared/widgets/product_pack_image.dart';
import 'order_history.dart';
import 'orders_repository.dart';
import 'widgets/orders_adaptive_grid.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialOrderId, this.initialOrderNumber});

  final int? initialOrderId;
  final String? initialOrderNumber;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _repository = OrdersRepository();
  final _searchController = TextEditingController();
  final _tabs = const ['All', 'Completed', 'Pending', 'Failed'];
  Timer? _searchTimer;
  List<MobileOrderSummary> _orders = const [];
  int _selectedTab = 0;
  bool _loading = true;
  bool _openedInitialOrder = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderNumber?.isNotEmpty == true) {
      _searchController.text = widget.initialOrderNumber!;
    } else if (widget.initialOrderId != null) {
      _searchController.text = widget.initialOrderId.toString();
    }
    _load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String? get _status => switch (_selectedTab) {
    1 => 'completed',
    2 => 'pending',
    3 => 'failed',
    _ => null,
  };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.fetchOrders(
        status: _status,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() => _orders = result.orders);
      _openInitialOrder(result.orders);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Orders could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openInitialOrder(List<MobileOrderSummary> orders) {
    final orderId = widget.initialOrderId;
    if (_openedInitialOrder || orderId == null) return;
    final matches = orders.where((order) => order.id == orderId);
    if (matches.isEmpty) return;
    _openedInitialOrder = true;
    final order = matches.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.push('/orders/detail', extra: order);
    });
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 450), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 3),
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
              _OrdersHeader(onRefresh: _load),
              const SizedBox(height: B2BSpacing.lg),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search order, package or customer',
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: B2BSpacing.xs),
                  itemBuilder: (context, index) => ChoiceChip(
                    label: Text(_tabs[index]),
                    selected: _selectedTab == index,
                    onSelected: (_) {
                      setState(() => _selectedTab = index);
                      _load();
                    },
                  ),
                ),
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (!_loading && _error == null && _orders.isNotEmpty) ...[
                _OrdersSummary(
                  label: _tabs[_selectedTab],
                  count: _orders.length,
                  total: _orders.fold<double>(
                    0,
                    (sum, order) => sum + order.amount,
                  ),
                  currency: _orders.first.currency,
                ),
                const SizedBox(height: B2BSpacing.md),
              ],
              if (_loading)
                const ContentLoadingState(label: 'Loading orders...')
              else if (_error != null)
                ContentErrorState(message: _error!, onRetry: _load)
              else if (_orders.isEmpty)
                ContentEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders found',
                  message: 'New eSIM purchases will appear here.',
                  actionLabel: 'Browse packages',
                  onAction: () => context.go('/packages'),
                )
              else
                OrdersAdaptiveGrid(
                  children: [
                    for (final order in _orders)
                      _OrderCard(
                        order: order,
                        onTap: () =>
                            context.push('/orders/detail', extra: order),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Orders', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: B2BSpacing.xxs),
              Text(
                'Track partner purchases and eSIM delivery status.',
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

class _OrdersSummary extends StatelessWidget {
  const _OrdersSummary({
    required this.label,
    required this.count,
    required this.total,
    required this.currency,
  });

  final String label;
  final int count;
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label sipariş',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: B2BSpacing.xxs),
                Text(
                  '$count kayıt',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$currency ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final MobileOrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final customer = order.customerName.trim().isEmpty
        ? 'Direct customer'
        : order.customerName.trim();
    final scheme = Theme.of(context).colorScheme;

    return B2BSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(B2BSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductPackImage(
                label: order.packageName,
                width: 48,
                height: 62,
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: B2BSpacing.xxs),
                    Text(
                      order.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.formattedAmount,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  _StatusBadge(status: order.status, color: color),
                ],
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: B2BSpacing.sm),
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: B2BSpacing.xs),
              Expanded(
                child: Text(
                  order.orderNumber.isEmpty
                      ? 'Order ${order.id}'
                      : order.orderNumber,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: B2BSpacing.xs),
              Text(
                _formatDate(order.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: B2BSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(B2BRadius.pill),
      ),
      child: Text(
        _titleCase(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _statusColor(String status) => switch (status.toLowerCase()) {
  'completed' || 'success' => AppColors.success,
  'failed' || 'cancelled' => AppColors.danger,
  _ => AppColors.warning,
};

String _titleCase(String value) {
  if (value.isEmpty) return 'Pending';
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Recently';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
}
