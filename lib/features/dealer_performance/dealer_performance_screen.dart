import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../orders/order_history.dart';
import '../orders/orders_repository.dart';

class DealerPerformanceScreen extends StatefulWidget {
  const DealerPerformanceScreen({super.key});

  @override
  State<DealerPerformanceScreen> createState() =>
      _DealerPerformanceScreenState();
}

class _DealerPerformanceScreenState extends State<DealerPerformanceScreen> {
  final _ordersRepository = OrdersRepository();
  List<MobileOrderSummary> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await _ordersRepository.fetchOrders();
      if (!mounted) return;
      setState(() => _orders = history.orders);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Dealer performance could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _completed(MobileOrderSummary order) {
    final status = order.status.toLowerCase();
    return status == 'completed' || status == 'success';
  }

  @override
  Widget build(BuildContext context) {
    final completed = _orders.where(_completed).toList(growable: false);
    final revenue = completed.fold<double>(
      0,
      (sum, order) => sum + order.amount,
    );
    final average = completed.isEmpty ? 0 : revenue / completed.length;
    final successRate = _orders.isEmpty
        ? 0
        : completed.length / _orders.length * 100;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Dealer Performance'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading && _orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _orders.isEmpty)
              _ErrorCard(message: _error!, onRetry: _load)
            else ...[
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _Metric(
                    label: 'Orders',
                    value: '${_orders.length}',
                    icon: Icons.receipt_long,
                  ),
                  _Metric(
                    label: 'Completed',
                    value: '${completed.length}',
                    icon: Icons.task_alt,
                  ),
                  _Metric(
                    label: 'Revenue',
                    value: completed.isEmpty
                        ? '—'
                        : '${completed.first.currency} ${revenue.toStringAsFixed(2)}',
                    icon: Icons.payments,
                  ),
                  _Metric(
                    label: 'Success rate',
                    value: '${successRate.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Metric(
                label: 'Average completed order',
                value: completed.isEmpty
                    ? '—'
                    : '${completed.first.currency} ${average.toStringAsFixed(2)}',
                icon: Icons.calculate,
              ),
              const SizedBox(height: 24),
              Text(
                'Recent orders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (_orders.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No dealer orders found.'),
                  ),
                )
              else
                ..._orders
                    .take(20)
                    .map(
                      (order) => Card(
                        child: ListTile(
                          title: Text(
                            order.orderNumber.isEmpty
                                ? 'Order #${order.id}'
                                : order.orderNumber,
                          ),
                          subtitle: Text(
                            '${order.customerName.isEmpty ? order.packageName : order.customerName} • ${order.status}',
                          ),
                          trailing: Text(order.formattedAmount),
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
