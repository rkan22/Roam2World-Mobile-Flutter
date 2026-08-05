import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'order_history.dart';
import 'orders_repository.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

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
  String? _error;

  @override
  void initState() {
    super.initState();
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
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Orders could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Orders', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  ),
                  IconButton.filledTonal(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search order or customer',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
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
              const SizedBox(height: 18),
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
                for (var index = 0; index < _orders.length; index++) ...[
                  _OrderTile(
                    order: _orders[index],
                    onTap: () => context.push('/orders/detail', extra: _orders[index]),
                  ),
                  if (index != _orders.length - 1) const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final MobileOrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.sim_card_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.packageName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(
                      order.orderNumber.isEmpty ? _formatDate(order.createdAt) : '${order.orderNumber} · ${_formatDate(order.createdAt)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(order.formattedAmount, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      _titleCase(order.status),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
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
