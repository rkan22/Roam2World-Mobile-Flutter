import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'package_catalog.dart';

class PackageDetailScreen extends StatelessWidget {
  const PackageDetailScreen({super.key, required this.package});

  final MobilePackage package;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ElevatedButton(
          onPressed: () => context.push('/checkout', extra: package),
          child: Text('Buy Now  •  ${package.formattedPrice}'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                IconButton.filledTonal(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
                const Expanded(child: Text('Package Detail', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 220,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.navy, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Text(_flagFor(package.countryCode), style: const TextStyle(fontSize: 34)), const Spacer(), const _FeaturePill(icon: Icons.network_cell_rounded, label: '4G / 5G')]),
                  const Spacer(),
                  Text(package.displayProvider, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(package.destination, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _PlanMetric(label: 'Data', value: package.dataLabel)),
                    Expanded(child: _PlanMetric(label: 'Validity', value: package.validityLabel)),
                    Expanded(child: _PlanMetric(label: 'Price', value: package.formattedPrice)),
                  ]),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  _InfoRow(icon: Icons.inventory_2_outlined, title: package.name, body: 'Package ID: ${package.id}'),
                  const SizedBox(height: 18),
                  _InfoRow(icon: Icons.public_rounded, title: 'Coverage', body: package.destination),
                  const SizedBox(height: 18),
                  const _InfoRow(icon: Icons.bolt_rounded, title: 'Activation', body: 'Installation details become available after the order is provisioned.'),
                  const SizedBox(height: 18),
                  const _InfoRow(icon: Icons.phone_iphone_rounded, title: 'Compatibility', body: 'Requires an unlocked eSIM-compatible device.'),
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
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
        child: Row(children: [Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),
      );
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)), const SizedBox(height: 5), Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 42, width: 42, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(body, style: const TextStyle(color: AppColors.textSecondary, height: 1.45))])),
      ]);
}

String _flagFor(String code) {
  if (code.length != 2) return '🌐';
  return code.toUpperCase().codeUnits.map((unit) => String.fromCharCode(unit + 127397)).join();
}
