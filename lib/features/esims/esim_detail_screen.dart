import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';

class EsimDetailScreen extends StatelessWidget {
  const EsimDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Expanded(
                  child: Text(
                    'eSIM Detail',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.navy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Orange · Turkey', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                      ),
                      _StatusBadge(),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text('10 GB · 30 Days · 5G', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                  SizedBox(height: 24),
                  Text('8.4 GB remaining', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    child: LinearProgressIndicator(value: .16, minHeight: 10, backgroundColor: Colors.white24, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text('1.6 GB used of 10 GB', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  const Text('Installation QR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Scan on the device where this eSIM will be installed.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  QrImageView(data: r'LPA:1$sm-v4-070-a-gtm.pr.go-esim.com$R2W-ESIM-001', size: 190),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_rounded), label: const Text('Download'))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.share_rounded), label: const Text('Share'))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _InfoCard(),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.copy_rounded), label: const Text('Copy activation details')),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(999)),
        child: const Text('Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
        child: const Column(
          children: [
            _InfoRow(label: 'Customer', value: 'Mehmet Yılmaz'),
            _InfoRow(label: 'ICCID', value: '8944501234567890123'),
            _InfoRow(label: 'Installed', value: '05 Aug 2026'),
            _InfoRow(label: 'Expires', value: '04 Sep 2026', last: true),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _InfoRow({required this.label, required this.value, this.last = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [Text(label, style: const TextStyle(color: AppColors.textSecondary)), const Spacer(), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900)))]),
      );
}
