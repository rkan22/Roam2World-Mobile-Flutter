import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'package_catalog.dart';

class PackageDetailScreen extends StatelessWidget {
  const PackageDetailScreen({super.key, required this.package});

  final MobilePackage package;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: () => context.push('/checkout', extra: package),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 19),
              const SizedBox(width: 8),
              Text('Continue to checkout  •  ${package.formattedPrice}'),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                IconButton.filledTonal(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
                Expanded(child: Text('Plan details', textAlign: TextAlign.center, style: theme.textTheme.titleLarge)),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 228,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: B2BGradients.primary,
                borderRadius: BorderRadius.circular(B2BRadius.xxl),
                boxShadow: B2BShadows.hero,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -28,
                    top: -32,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(18)),
                            child: Text(_flagFor(package.countryCode), style: const TextStyle(fontSize: 31)),
                          ),
                          const Spacer(),
                          const _FeaturePill(icon: Icons.network_cell_rounded, label: '4G / 5G'),
                        ],
                      ),
                      const Spacer(),
                      Text(package.displayProvider, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(package.destination, style: const TextStyle(color: Colors.white, fontSize: 30, letterSpacing: -0.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(package.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .78), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(B2BRadius.xl),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
              ),
              child: Row(
                children: [
                  Expanded(child: _PlanMetric(label: 'Data', value: package.dataLabel, icon: Icons.data_usage_rounded)),
                  _Divider(),
                  Expanded(child: _PlanMetric(label: 'Validity', value: package.validityLabel, icon: Icons.schedule_rounded)),
                  _Divider(),
                  Expanded(child: _PlanMetric(label: 'Price', value: package.formattedPrice, icon: Icons.payments_outlined)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Plan information', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(B2BRadius.xl),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
              ),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.inventory_2_outlined, title: 'Package', body: package.name, trailing: '#${package.id}'),
                  const Divider(height: 28),
                  _InfoRow(icon: Icons.public_rounded, title: 'Coverage', body: package.destination),
                  const Divider(height: 28),
                  const _InfoRow(icon: Icons.bolt_rounded, title: 'Activation', body: 'QR and activation details appear after provisioning.'),
                  const Divider(height: 28),
                  const _InfoRow(icon: Icons.phone_iphone_rounded, title: 'Compatibility', body: 'Unlocked eSIM-compatible devices are required.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(B2BRadius.lg)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.business_center_outlined, color: AppColors.accent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('B2B fulfilment', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Complete checkout to provision this package to your customer and manage it from the eSIM workspace.', style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 48, color: Theme.of(context).colorScheme.outlineVariant);
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
  const _PlanMetric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 7),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body, this.trailing});
  final IconData icon;
  final String title;
  final String body;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                    if (trailing != null) Text(trailing!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
}

String _flagFor(String code) {
  if (code.length != 2) return '🌐';
  return code.toUpperCase().codeUnits.map((unit) => String.fromCharCode(unit + 127397)).join();
}
