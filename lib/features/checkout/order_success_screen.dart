import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../orders/order_result.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.result});

  final MobileOrderResult result;

  @override
  Widget build(BuildContext context) {
    final hasInstall = result.installAvailable || (result.qrCode?.isNotEmpty ?? false) || (result.activationCode?.isNotEmpty ?? false);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(height: 96, width: 96, decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: AppColors.success, size: 54)),
              const SizedBox(height: 24),
              const Text('Order completed', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                hasInstall ? 'The eSIM has been created and installation details are available.' : 'The order was accepted. Installation details will appear after provisioning.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                child: Column(children: [
                  _SuccessRow(label: 'Order ID', value: result.orderNumber.isNotEmpty ? result.orderNumber : result.orderId),
                  _SuccessRow(label: 'Package', value: result.packageName),
                  _SuccessRow(label: 'Customer', value: result.customerName.isEmpty ? 'Customer' : result.customerName),
                  _SuccessRow(label: 'Status', value: result.status),
                  _SuccessRow(label: 'Total', value: result.formattedTotal, last: true),
                ]),
              ),
              const Spacer(),
              if (result.esimId != null || hasInstall)
                ElevatedButton.icon(
                  onPressed: () => context.go('/esims'),
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text('View eSIM & QR'),
                )
              else
                ElevatedButton.icon(onPressed: () => context.go('/orders'), icon: const Icon(Icons.receipt_long_outlined), label: const Text('View orders')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => context.go('/packages'), child: const Text('Buy another package')),
              TextButton(onPressed: () => context.go('/dashboard'), child: const Text('Back to home')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [Text(label, style: const TextStyle(color: AppColors.textSecondary)), const Spacer(), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900)))]),
      );
}
