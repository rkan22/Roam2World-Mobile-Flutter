import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../orders/order_history.dart';

class CustomerDetailArgs {
  const CustomerDetailArgs({
    required this.name,
    required this.orders,
    required this.totalSpend,
    required this.currency,
    required this.lastOrderAt,
    required this.orderHistory,
  });

  final String name;
  final int orders;
  final double totalSpend;
  final String currency;
  final DateTime? lastOrderAt;
  final List<MobileOrderSummary> orderHistory;
}

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final CustomerDetailArgs customer;

  @override
  Widget build(BuildContext context) {
    final completed = customer.orderHistory.where((order) => _isCompleted(order.status)).length;
    final pending = customer.orderHistory.where((order) => _isPending(order.status)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer details'),
        actions: [
          IconButton(
            tooltip: 'New order',
            onPressed: () => context.go('/packages'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
          ),
          const SizedBox(width: B2BSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          B2BSpacing.lg,
          B2BSpacing.sm,
          B2BSpacing.lg,
          B2BSpacing.xxl,
        ),
        children: [
          _CustomerHero(customer: customer),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Orders', value: '${customer.orders}')),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(child: _Metric(label: 'Completed', value: '$completed')),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(child: _Metric(label: 'Pending', value: '$pending')),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.go('/packages'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Create new order'),
          ),
          const SizedBox(height: B2BSpacing.xl),
          Text('Order history', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: B2BSpacing.sm),
          if (customer.orderHistory.isEmpty)
            const B2BSurface(
              child: Text('No order history is available for this customer.'),
            )
          else
            B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < customer.orderHistory.length; index++) ...[
                    _OrderRow(order: customer.orderHistory[index]),
                    if (index < customer.orderHistory.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerHero extends StatelessWidget {
  const _CustomerHero({required this.customer});

  final CustomerDetailArgs customer;

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      backgroundColor: AppColors.navy,
      borderColor: AppColors.navy,
      padding: const EdgeInsets.all(B2BSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(B2BRadius.lg),
                ),
                child: Text(
                  _initials(customer.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: B2BSpacing.xxs),
                    Text(
                      'Last order ${_formatDate(customer.lastOrderAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.xl),
          Text(
            '${customer.currency} ${customer.totalSpend.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: B2BSpacing.xxs),
          const Text(
            'Lifetime order volume',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      padding: const EdgeInsets.all(B2BSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: B2BSpacing.xxs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final MobileOrderSummary order;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: B2BSpacing.md,
        vertical: B2BSpacing.xs,
      ),
      onTap: () => context.push('/orders/detail'),
      title: Text(
        order.packageName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${order.orderNumber} · ${_formatDate(order.createdAt)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(order.formattedAmount, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            order.status,
            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

bool _isCompleted(String status) => RegExp(r'complete|success|deliver|active', caseSensitive: false).hasMatch(status);
bool _isPending(String status) => RegExp(r'pending|process|provision|await', caseSensitive: false).hasMatch(status);

Color _statusColor(String status) {
  if (_isCompleted(status)) return AppColors.success;
  if (_isPending(status)) return AppColors.warning;
  if (RegExp(r'fail|cancel|refund', caseSensitive: false).hasMatch(status)) return AppColors.danger;
  return AppColors.textSecondary;
}

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _formatDate(DateTime? date) {
  if (date == null) return 'not available';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
}
