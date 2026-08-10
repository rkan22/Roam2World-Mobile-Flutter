import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'order_history.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final MobileOrderSummary order;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final customer = order.customerName.trim().isEmpty
        ? 'Direct customer'
        : order.customerName.trim();
    final orderNumber = order.orderNumber.trim().isEmpty
        ? 'Order #${order.id}'
        : order.orderNumber.trim();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.md,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order detail', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: B2BSpacing.xxs),
                      Text(orderNumber, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: B2BSpacing.lg),
            Container(
              padding: const EdgeInsets.all(B2BSpacing.xl),
              decoration: BoxDecoration(
                gradient: B2BGradients.primary,
                borderRadius: BorderRadius.circular(B2BRadius.xl),
                boxShadow: B2BShadows.hero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(B2BRadius.md),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(B2BRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _titleCase(order.status),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: B2BSpacing.xl),
                  Text(
                    order.packageName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  Text(customer, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                  const SizedBox(height: B2BSpacing.xl),
                  Row(
                    children: [
                      Expanded(child: _HeroMetric(label: 'Amount', value: order.formattedAmount)),
                      Container(width: 1, height: 38, color: Colors.white24),
                      Expanded(child: _HeroMetric(label: 'Created', value: _compactDate(order.createdAt))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.lg),
            Text('Order information', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: B2BSpacing.sm),
            B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _DetailRow(label: 'Order', value: orderNumber),
                  _DetailRow(label: 'Customer', value: customer),
                  _DetailRow(label: 'Package', value: order.packageName),
                  _DetailRow(label: 'Amount', value: order.formattedAmount),
                  _DetailRow(
                    label: 'Status',
                    value: _titleCase(order.status),
                    valueColor: statusColor,
                  ),
                  _DetailRow(label: 'Created', value: _fullDate(order.createdAt), last: true),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.lg),
            Text('Provisioning', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: B2BSpacing.sm),
            B2BSurface(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: order.esimId == null ? AppColors.warningSoft : AppColors.successSoft,
                      borderRadius: BorderRadius.circular(B2BRadius.md),
                    ),
                    child: Icon(
                      order.esimId == null ? Icons.hourglass_top_rounded : Icons.sim_card_rounded,
                      color: order.esimId == null ? AppColors.warning : AppColors.success,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.esimId == null ? 'eSIM provisioning pending' : 'eSIM linked to this order',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: B2BSpacing.xxs),
                        Text(
                          order.esimId == null
                              ? 'Installation data will be available once provisioning is complete.'
                              : 'eSIM ID ${order.esimId}. Open My eSIMs to manage installation and activation.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.go('/esims'),
              icon: const Icon(Icons.sim_card_outlined),
              label: const Text('Open My eSIMs'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: B2BSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor, this.last = false});

  final String label;
  final String value;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: B2BSpacing.md, vertical: 15),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w800, color: valueColor),
              ),
            ),
          ],
        ),
      );
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

String _compactDate(DateTime? date) {
  if (date == null) return 'Recently';
  return DateFormat('dd MMM').format(date.toLocal());
}

String _fullDate(DateTime? date) {
  if (date == null) return 'Not available';
  return DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());
}
