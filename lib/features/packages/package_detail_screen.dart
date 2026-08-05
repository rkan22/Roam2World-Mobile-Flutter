import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class PackageDetailScreen extends StatelessWidget {
  const PackageDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ElevatedButton(
          onPressed: () => context.push('/checkout'),
          child: const Text('Buy Now  •  \$15.00'),
        ),
      ),
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
                    'Package Detail',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 220,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, AppColors.primary],
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
                      Text('🇹🇷', style: TextStyle(fontSize: 34)),
                      Spacer(),
                      _FeaturePill(icon: Icons.network_cell_rounded, label: '5G'),
                    ],
                  ),
                  Spacer(),
                  Text('Orange', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Turkey', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _PlanMetric(label: 'Data', value: '10 GB')),
                      Expanded(child: _PlanMetric(label: 'Validity', value: '30 Days')),
                      Expanded(child: _PlanMetric(label: 'Price', value: '\$15.00')),
                    ],
                  ),
                  SizedBox(height: 20),
                  Divider(height: 1),
                  SizedBox(height: 20),
                  _InfoRow(icon: Icons.speed_rounded, title: 'High-speed data', body: 'Reliable 4G/5G coverage across Turkey.'),
                  SizedBox(height: 18),
                  _InfoRow(icon: Icons.public_rounded, title: 'Coverage', body: 'Works on leading local partner networks.'),
                  SizedBox(height: 18),
                  _InfoRow(icon: Icons.bolt_rounded, title: 'Activation', body: 'Activates automatically after first network connection.'),
                  SizedBox(height: 18),
                  _InfoRow(icon: Icons.phone_iphone_rounded, title: 'Compatibility', body: 'Supports unlocked eSIM-compatible devices.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(999)),
        child: Row(children: [Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),
      );
}

class _PlanMetric extends StatelessWidget {
  final String label;
  final String value;
  const _PlanMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)), const SizedBox(height: 5), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoRow({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 42, width: 42, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(body, style: const TextStyle(color: AppColors.textSecondary, height: 1.45))]))]);
}
