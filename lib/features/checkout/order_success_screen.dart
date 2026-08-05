import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                height: 96,
                width: 96,
                decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 54),
              ),
              const SizedBox(height: 24),
              const Text('Order completed', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text(
                'The eSIM has been created and the installation details are ready.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                child: const Column(
                  children: [
                    _SuccessRow(label: 'Order ID', value: '#ORD-2026-000125'),
                    _SuccessRow(label: 'Package', value: 'Turkey · 10 GB'),
                    _SuccessRow(label: 'Customer', value: 'Mehmet Yılmaz'),
                    _SuccessRow(label: 'Total', value: '\$15.00', last: true),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context.go('/orders/detail'),
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('View QR & Order'),
              ),
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
  final String label;
  final String value;
  final bool last;
  const _SuccessRow({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
        ]),
      );
}
