import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'sim_card_models.dart';
import 'sim_cards_repository.dart';

class SimCardOrderHistoryScreen extends StatefulWidget {
  const SimCardOrderHistoryScreen({super.key});

  @override
  State<SimCardOrderHistoryScreen> createState() => _SimCardOrderHistoryScreenState();
}

class _SimCardOrderHistoryScreenState extends State<SimCardOrderHistoryScreen> {
  final _repository = SimCardsRepository();
  List<SimCardOrder> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await _repository.fetchOrders();
      if (mounted) setState(() => _orders = orders);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'SIM orders could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(BuildContext context, String status) {
    final value = status.toLowerCase();
    if (value.contains('fail') || value.contains('cancel')) return Theme.of(context).colorScheme.error;
    if (value.contains('complete') || value.contains('deliver')) return Colors.green;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SIM Orders', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 5),
                  Text('Track your physical SIM stock orders.', style: theme.textTheme.bodyMedium),
                ])),
                IconButton.filledTonal(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
              ]),
              const SizedBox(height: B2BSpacing.lg),
              if (_loading)
                const ContentLoadingState(label: 'Loading SIM orders...')
              else if (_error != null)
                ContentErrorState(message: _error!, onRetry: _load)
              else if (_orders.isEmpty)
                const ContentEmptyState(icon: Icons.local_shipping_outlined, title: 'No SIM orders', message: 'Physical SIM stock orders will appear here.')
              else
                for (final order in _orders) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(order.orderNumber.isEmpty ? 'SIM Order' : order.orderNumber, style: theme.textTheme.titleMedium)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: _statusColor(context, order.status).withValues(alpha: .12), borderRadius: BorderRadius.circular(B2BRadius.pill)),
                            child: Text(order.status, style: theme.textTheme.labelMedium?.copyWith(color: _statusColor(context, order.status), fontWeight: FontWeight.w800)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Text(order.productName, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text('${order.quantity} × SIM', style: theme.textTheme.bodyMedium),
                          const Spacer(),
                          Text('${order.currency} ${order.totalAmount.toStringAsFixed(2)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                        ]),
                        if (order.providerOrderId != null && order.providerOrderId!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Fulfillment: ${order.providerOrderId}', style: theme.textTheme.bodySmall),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
