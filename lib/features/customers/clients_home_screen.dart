import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import '../orders/order_history.dart';
import '../orders/orders_repository.dart';
import 'customer_detail_screen.dart';

class ClientsHomeScreen extends StatefulWidget {
  const ClientsHomeScreen({super.key});

  @override
  State<ClientsHomeScreen> createState() => _ClientsHomeScreenState();
}

class _ClientsHomeScreenState extends State<ClientsHomeScreen> {
  final _repository = OrdersRepository();
  final _search = TextEditingController();
  List<_ClientRow> _clients = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _clients.isEmpty;
      _error = null;
    });
    try {
      final history = await _repository.fetchOrders();
      if (!mounted) return;
      setState(() => _clients = _aggregate(history.orders));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Clients could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_ClientRow> get _visible {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _clients;
    return _clients.where((item) => item.name.toLowerCase().contains(query) || item.email.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final orders = visible.fold<int>(0, (sum, item) => sum + item.orders.length);
    final spend = visible.fold<double>(0, (sum, item) => sum + item.totalSpend);
    final currency = visible.isEmpty ? 'USD' : visible.first.currency;

    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.md, B2BSpacing.lg, B2BSpacing.xxxl),
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Client Management', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: B2BSpacing.xs),
                  const Text('Customers derived from your real order activity.', style: TextStyle(color: AppColors.textSecondary)),
                ])),
                IconButton.filledTonal(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
              ]),
              const SizedBox(height: B2BSpacing.lg),
              TextField(
                controller: _search,
                decoration: const InputDecoration(hintText: 'Search client or email', prefixIcon: Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: B2BSpacing.lg),
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Clients', value: '${visible.length}', icon: Icons.groups_outlined)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Orders', value: '$orders', icon: Icons.receipt_long_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.sm),
              B2BMetricCard(label: 'Order value', value: '$currency ${spend.toStringAsFixed(2)}', icon: Icons.payments_outlined),
              const SizedBox(height: B2BSpacing.xl),
              if (_loading)
                const ContentLoadingState(label: 'Loading clients...')
              else if (_error != null)
                ContentErrorState(message: _error!, onRetry: _load)
              else if (visible.isEmpty)
                const ContentEmptyState(icon: Icons.groups_outlined, title: 'No clients found', message: 'Clients appear after customer orders are created.')
              else
                for (final client in visible) ...[
                  B2BSurface(
                    onTap: () => context.push('/customers/detail', extra: CustomerDetailArgs(
                      name: client.name,
                      orders: client.orders.length,
                      totalSpend: client.totalSpend,
                      currency: client.currency,
                      lastOrderAt: client.lastOrderAt,
                      orderHistory: client.orders,
                    )),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(_initials(client.name), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(client.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                        if (client.email.isNotEmpty) Text(client.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                        Text('${client.orders.length} orders', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ])),
                      const SizedBox(width: B2BSpacing.sm),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${client.currency} ${client.totalSpend.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientRow {
  const _ClientRow({required this.name, required this.email, required this.orders, required this.totalSpend, required this.currency, required this.lastOrderAt});
  final String name;
  final String email;
  final List<MobileOrderSummary> orders;
  final double totalSpend;
  final String currency;
  final DateTime? lastOrderAt;
}

List<_ClientRow> _aggregate(List<MobileOrderSummary> orders) {
  final groups = <String, List<MobileOrderSummary>>{};
  for (final order in orders) {
    final name = order.customerName.trim().isEmpty ? order.customerEmail.trim() : order.customerName.trim();
    if (name.isEmpty) continue;
    groups.putIfAbsent(name.toLowerCase(), () => []).add(order);
  }
  final rows = groups.values.map((items) {
    items.sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    final first = items.first;
    return _ClientRow(
      name: first.customerName.trim().isEmpty ? first.customerEmail : first.customerName,
      email: first.customerEmail,
      orders: List.unmodifiable(items),
      totalSpend: items.fold(0, (sum, item) => sum + item.amount),
      currency: first.currency,
      lastOrderAt: first.createdAt,
    );
  }).toList();
  rows.sort((a, b) => (b.lastOrderAt ?? DateTime(1970)).compareTo(a.lastOrderAt ?? DateTime(1970)));
  return rows;
}

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((item) => item.isNotEmpty).take(2);
  return parts.isEmpty ? 'C' : parts.map((item) => item[0].toUpperCase()).join();
}
