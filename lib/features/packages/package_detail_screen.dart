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
    final typeLabel = package.packageType == 'simcard' ? 'SIM Card' : 'eSIM';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 58,
          child: FilledButton.icon(
            onPressed: package.isPriceAvailable
                ? () => context.push('/checkout', extra: package)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.shopping_bag_outlined, size: 20),
            label: Text(
              package.isPriceAvailable
                  ? 'Continue to checkout  •  ${package.formattedPrice}'
                  : 'Contact Admin',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    'Plan details',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 18),
            _PlanSummaryCard(package: package, typeLabel: typeLabel),
            const SizedBox(height: 14),
            _MetricsCard(package: package),
            if (package.description.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                'About this plan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _SurfaceCard(
                child: Text(
                  package.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Text(
              'Plan information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.inventory_2_outlined,
                    title: 'Package',
                    body: package.name,
                    tone: const Color(0xFF334155),
                    soft: const Color(0xFFF1F5F9),
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.public_rounded,
                    title: 'Coverage',
                    body: package.destination,
                    tone: const Color(0xFF7C3AED),
                    soft: const Color(0xFFF5F3FF),
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.sim_card_outlined,
                    title: 'Type',
                    body: typeLabel,
                    tone: const Color(0xFFEA580C),
                    soft: const Color(0xFFFFF7ED),
                  ),
                  if (package.supportedCountries.isNotEmpty) ...[
                    const Divider(height: 1),
                    _SupportedCountriesRow(
                      countries: package.supportedCountries,
                    ),
                  ],
                  const Divider(height: 1),
                  const _InfoRow(
                    icon: Icons.bolt_rounded,
                    title: 'Activation',
                    body:
                        'QR and activation details appear after provisioning.',
                    tone: Color(0xFF475569),
                    soft: Color(0xFFF1F5F9),
                  ),
                  const Divider(height: 1),
                  const _InfoRow(
                    icon: Icons.phone_iphone_rounded,
                    title: 'Compatibility',
                    body: 'Unlocked eSIM-compatible devices are required.',
                    tone: Color(0xFF166534),
                    soft: Color(0xFFF0FDF4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(B2BRadius.lg),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.business_center_outlined,
                    color: Color(0xFF475569),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'B2B fulfilment',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete checkout to provision this package to your customer and manage it from the eSIM workspace.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
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

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.package, required this.typeLabel});

  final MobilePackage package;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light
            ? const [
                BoxShadow(
                  color: Color(0x12020817),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _CountryFlag(code: package.countryCode),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.displayProvider,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package.destination,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            package.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    package.isPriceAvailable
                        ? 'Ready for B2B checkout'
                        : 'Central pricing required',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  package.formattedPrice,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.package});

  final MobilePackage package;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: _PlanMetric(
              label: 'Data',
              value: package.dataLabel,
              icon: Icons.data_usage_rounded,
              tone: const Color(0xFF334155),
              soft: const Color(0xFFF1F5F9),
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _PlanMetric(
              label: 'Validity',
              value: package.validityLabel,
              icon: Icons.schedule_rounded,
              tone: const Color(0xFF7C3AED),
              soft: const Color(0xFFF5F3FF),
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _PlanMetric(
              label: 'Price',
              value: package.formattedPrice,
              icon: Icons.payments_outlined,
              tone: const Color(0xFFEA580C),
              soft: const Color(0xFFFFF7ED),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light
            ? B2BShadows.card
            : null,
      ),
      child: child,
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 62,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    required this.soft,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;
  final Color soft;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 18, color: tone),
      ),
      const SizedBox(height: 7),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.tone,
    required this.soft,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color tone;
  final Color soft;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: tone, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SupportedCountriesRow extends StatelessWidget {
  const _SupportedCountriesRow({required this.countries});

  final List<PackageCountry> countries;

  @override
  Widget build(BuildContext context) {
    const visibleCount = 6;
    final visible = countries.take(visibleCount).toList(growable: false);
    final remaining = countries.length - visible.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: Color(0xFF2563EB),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supported countries',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final country in visible)
                      _CircularCountryFlag(code: country.code),
                    if (remaining > 0)
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+$remaining',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularCountryFlag extends StatelessWidget {
  const _CircularCountryFlag({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 2) {
      return Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.public_rounded,
          size: 16,
          color: Color(0xFF475569),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        'https://flagsapi.com/$normalized/flat/64.png',
        width: 30,
        height: 30,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Text(
            normalized,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryFlag extends StatelessWidget {
  const _CountryFlag({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    const width = 40.0;
    if (code.length != 2) {
      return const Icon(
        Icons.public_rounded,
        color: Color(0xFF475569),
        size: 29,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        'https://flagsapi.com/${code.toUpperCase()}/flat/64.png',
        width: width,
        height: width * .7,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: width * .7,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            code.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
