import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'order_history.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final MobileOrderSummary order;

  Future<void> _copy(BuildContext context, String value, String label) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final customer = order.customerName.trim().isEmpty
        ? 'Customer assignment pending'
        : order.customerName.trim();
    final installValue = order.qrCode.isNotEmpty ? order.qrCode : order.activationCode;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Order details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          B2BSpacing.lg,
          B2BSpacing.xs,
          B2BSpacing.lg,
          B2BSpacing.xxl,
        ),
        children: [
          B2BSurface(
            backgroundColor: AppColors.navy,
            borderColor: AppColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber.isEmpty ? 'Order ${order.id}' : order.orderNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                ),
                const SizedBox(height: B2BSpacing.xs),
                Text(
                  order.packageName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: B2BSpacing.md),
                Row(
                  children: [
                    _StatusPill(status: order.status, color: statusColor),
                    const Spacer(),
                    Text(
                      order.formattedAmount,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: B2BSpacing.md),
          B2BSurface(
            child: Column(
              children: [
                _DetailRow(label: 'Customer', value: customer),
                if (order.customerEmail.isNotEmpty)
                  _DetailRow(label: 'Email', value: order.customerEmail),
                _DetailRow(
                  label: 'ICCID',
                  value: order.iccid.isEmpty ? 'Provisioning' : order.iccid,
                  onCopy: order.iccid.isEmpty
                      ? null
                      : () => _copy(context, order.iccid, 'ICCID'),
                ),
                _DetailRow(
                  label: 'Order type',
                  value: order.orderType.isEmpty ? 'eSIM' : order.orderType,
                ),
                _DetailRow(
                  label: 'Created',
                  value: _formatDateTime(order.createdAt),
                  last: true,
                ),
              ],
            ),
          ),
          if (order.hasInstallData) ...[
            const SizedBox(height: B2BSpacing.md),
            B2BSurface(
              child: Column(
                children: [
                  Text(
                    'eSIM installation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  Text(
                    'Use the provider-issued QR or activation string below.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: B2BSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(B2BSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(B2BRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: QrImageView(data: installValue, size: 190),
                  ),
                  const SizedBox(height: B2BSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => _copy(context, installValue, 'Activation data'),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy activation data'),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: B2BSpacing.md),
            B2BSurface(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(B2BRadius.md),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Provisioning in progress',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Installation details will appear when the provider returns them.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: B2BSpacing.md),
          FilledButton.icon(
            onPressed: () => context.go('/packages'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Create another order'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.onCopy,
    this.last = false,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: B2BSpacing.sm),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: B2BSpacing.xs),
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(B2BRadius.pill),
      ),
      child: Text(
        _titleCase(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

Color _statusColor(String status) {
  final value = status.toLowerCase();
  if (['active', 'activated', 'installed', 'completed', 'approved', 'delivered', 'success'].contains(value)) {
    return AppColors.success;
  }
  if (['failed', 'expired', 'cancelled', 'canceled', 'declined'].contains(value)) {
    return AppColors.danger;
  }
  return AppColors.warning;
}

String _titleCase(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) return 'Processing';
  return normalized
      .split(' ')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Not available';
  final local = value.toLocal();
  final date = '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date · $time';
}
