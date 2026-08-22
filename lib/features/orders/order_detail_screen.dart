import 'package:flutter/material.dart';

import '../../shared/widgets/r2w_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../esims/esims_repository.dart';
import 'order_history.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final MobileOrderSummary order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final EsimsRepository _esimsRepository = EsimsRepository();
  bool _openingLinkedSim = false;

  MobileOrderSummary get order => widget.order;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/orders');
    }
  }

  Future<void> _openLinkedSim() async {
    final esimId = order.esimId;
    if (esimId == null || _openingLinkedSim) return;

    setState(() => _openingLinkedSim = true);
    try {
      final linked = await _esimsRepository.fetchEsimDetail(esimId);
      if (!mounted) return;
      context.push('/esims/detail', extra: linked);
    } catch (_) {
      if (!mounted) return;
      R2WToast.error(context, 'Linked SIM / eSIM details could not be loaded.');
    } finally {
      if (mounted) setState(() => _openingLinkedSim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(order.status);
    final customer = order.customerName.trim().isEmpty
        ? 'Direct customer'
        : order.customerName.trim();
    final orderNumber = order.orderNumber.trim().isEmpty
        ? 'Order #${order.id}'
        : order.orderNumber.trim();
    final hasLinkedSim = order.esimId != null;

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
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order detail',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: B2BSpacing.xxs),
                      Text(orderNumber, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: B2BSpacing.lg),
            Container(
              padding: const EdgeInsets.all(B2BSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(B2BRadius.xl),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: theme.brightness == Brightness.light
                    ? B2BShadows.card
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(B2BRadius.md),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.packageName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: B2BSpacing.xxs),
                            Text(
                              customer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      _StatusPill(
                        label: _titleCase(order.status),
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: B2BSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Amount',
                          value: order.formattedAmount,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(
                        child: _MetricTile(
                          label: 'Created',
                          value: _compactDate(order.createdAt),
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.xl),
            Text('Order information', style: theme.textTheme.titleLarge),
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
                  _DetailRow(
                    label: 'Created',
                    value: _fullDate(order.createdAt),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.xl),
            Text('Provisioning', style: theme.textTheme.titleLarge),
            const SizedBox(height: B2BSpacing.sm),
            B2BSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: hasLinkedSim
                              ? AppColors.successSoft
                              : AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(B2BRadius.md),
                        ),
                        child: Icon(
                          hasLinkedSim
                              ? Icons.sim_card_rounded
                              : Icons.hourglass_top_rounded,
                          color: hasLinkedSim
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasLinkedSim
                                  ? 'Purchased line is ready'
                                  : 'Provisioning pending',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: B2BSpacing.xxs),
                            Text(
                              hasLinkedSim
                                  ? 'Open the exact SIM / eSIM linked to this order.'
                                  : 'The purchased line will appear when provisioning completes.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasLinkedSim) ...[
                    const SizedBox(height: B2BSpacing.md),
                    Divider(color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: B2BSpacing.sm),
                    Row(
                      children: [
                        Text(
                          'SIM / eSIM ID',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${order.esimId}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.lg),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: hasLinkedSim && !_openingLinkedSim
                    ? _openLinkedSim
                    : null,
                icon: _openingLinkedSim
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sim_card_outlined),
                label: Text(
                  _openingLinkedSim
                      ? 'Opening...'
                      : 'Open purchased SIM / eSIM',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(B2BSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(B2BRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(B2BRadius.pill),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.last = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: B2BSpacing.md,
      vertical: 15,
    ),
    decoration: BoxDecoration(
      border: last
          ? null
          : Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
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
