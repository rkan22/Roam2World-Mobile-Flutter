import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(children: [
              IconButton.filledTonal(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
              const Expanded(child: Text('Order Detail', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded)),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
              child: const Column(children: [
                _DetailRow(label: 'Order ID', value: '#ORD-2026-000124'),
                _DetailRow(label: 'Customer', value: 'Mehmet Yılmaz'),
                _DetailRow(label: 'Package', value: 'Turkey · 10 GB'),
                _DetailRow(label: 'Amount', value: '\$15.00'),
                _DetailRow(label: 'Status', value: 'Completed', valueColor: AppColors.success, last: true),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
              child: Column(children: [
                const Text('eSIM QR Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Scan this code on the destination device.', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                  child: QrImageView(data: r'LPA:1$sm-v4-070-a-gtm.pr.go-esim.com$R2W-2026-000124', size: 190),
                ),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_rounded), label: const Text('Download'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.share_rounded), label: const Text('Share'))),
                ]),
                const SizedBox(height: 10),
                ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.mail_outline_rounded), label: const Text('Resend Email')),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(24)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Activation information', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                SizedBox(height: 14),
                _InfoLine(icon: Icons.schedule_rounded, text: 'Created: 05 Aug 2026, 21:30'),
                SizedBox(height: 10),
                _InfoLine(icon: Icons.event_rounded, text: 'Expires: 04 Sep 2026, 21:30'),
                SizedBox(height: 10),
                _InfoLine(icon: Icons.sim_card_rounded, text: 'ICCID: 8944501234567890123'),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool last;
  const _DetailRow({required this.label, required this.value, this.valueColor, this.last = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [Text(label, style: const TextStyle(color: AppColors.textSecondary)), const Spacer(), Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w900, color: valueColor ?? AppColors.textPrimary)))]),
      );
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 20, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)))]);
}
