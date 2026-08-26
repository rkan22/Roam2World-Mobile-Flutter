import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/package_destination_visual.dart';
import '../../shared/widgets/package_type_chip.dart';
import '../auth/auth_repository.dart';
import 'package_catalog.dart';

class PackageDetailScreen extends StatefulWidget {
  const PackageDetailScreen({
    super.key,
    required this.package,
    this.roleOverride,
  });

  final MobilePackage package;
  final AppRole? roleOverride;

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final _authRepository = AuthRepository();
  AppRole _role = AppRole.unknown;

  MobilePackage get package => widget.package;

  @override
  void initState() {
    super.initState();
    _role = widget.roleOverride ?? AppRole.unknown;
    if (widget.roleOverride == null) _loadRole();
  }

  Future<void> _loadRole() async {
    final profile = await _authRepository.readStoredProfile();
    if (!mounted) return;
    setState(() => _role = parseAppRole(profile?.role));
  }

  @override
  Widget build(BuildContext context) {
    final isPhysical = package.packageType.toLowerCase() == 'simcard';
    final typeLabel = isPhysical ? 'SIM Card' : 'eSIM';
    final isAdmin = _role == AppRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Details'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'More',
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: SizedBox(
          height: 58,
          child: FilledButton.icon(
            onPressed: package.isPriceAvailable
                ? () => context.push('/checkout', extra: package)
                : isAdmin
                ? () => context.push('/pricing/rules')
                : null,
            icon: Icon(
              package.isPriceAvailable
                  ? Icons.shopping_cart_outlined
                  : Icons.support_agent_rounded,
            ),
            label: Text(
              package.isPriceAvailable
                  ? 'Add to cart'
                  : isAdmin
                  ? 'Configure pricing'
                  : 'Contact Admin',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          _ProductCard(
            package: package,
            typeLabel: typeLabel,
            isAdmin: isAdmin,
          ),
          const SizedBox(height: 14),
          _OverviewCard(package: package, isPhysical: isPhysical),
          const SizedBox(height: 14),
          _PlanInformationCard(package: package, typeLabel: typeLabel),
          const SizedBox(height: 14),
          _ImportantNotesCard(package: package, isPhysical: isPhysical),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.package,
    required this.typeLabel,
    required this.isAdmin,
  });

  final MobilePackage package;
  final String typeLabel;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  package.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const _LiveBadge(),
              const SizedBox(width: 10),
              PackageDestinationVisual(
                code: package.countryCode,
                destinationKey: '',
                size: 38,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            package.displayProvider,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PackageTypeChip(packageType: package.packageType),
              _ValueChip(icon: Icons.storage_rounded, label: package.dataLabel),
              _ValueChip(
                icon: Icons.calendar_month_outlined,
                label: package.validityLabel,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB9E1FF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        package.isPriceAvailable
                            ? package.formattedPrice
                            : 'On request',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!package.isPriceAvailable) ...[
                        const SizedBox(height: 3),
                        const Text(
                          'Central pricing required',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: package.isPriceAvailable
                      ? () => context.push('/checkout', extra: package)
                      : isAdmin
                      ? () => context.push('/pricing/rules')
                      : null,
                  icon: Icon(
                    package.isPriceAvailable
                        ? Icons.shopping_cart_outlined
                        : Icons.chat_bubble_outline_rounded,
                    size: 18,
                  ),
                  label: Text(
                    package.isPriceAvailable
                        ? 'Add to cart'
                        : isAdmin
                        ? 'Configure pricing'
                        : 'Contact Admin',
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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.package, required this.isPhysical});

  final MobilePackage package;
  final bool isPhysical;

  @override
  Widget build(BuildContext context) {
    final fallback =
        '${package.name} provides ${package.dataLabel} of high-speed data '
        'for ${package.validityLabel} across ${package.destination}.';

    return _DetailCard(
      title: 'Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            package.description.trim().isEmpty ? fallback : package.description,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8FF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFB9E1FF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPhysical
                        ? 'This SIM Card is available for B2B ordering.'
                        : 'This eSIM can be provisioned after checkout.',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
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

class _PlanInformationCard extends StatelessWidget {
  const _PlanInformationCard({required this.package, required this.typeLabel});

  final MobilePackage package;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Plan Information',
      child: Column(
        children: [
          _IconDataRow(
            icon: Icons.sim_card_outlined,
            label: 'Type',
            value: typeLabel,
          ),
          const Divider(height: 1),
          _IconDataRow(
            icon: Icons.storage_rounded,
            label: 'Data',
            value: package.dataLabel,
          ),
          const Divider(height: 1),
          _IconDataRow(
            icon: Icons.calendar_month_outlined,
            label: 'Validity',
            value: package.validityLabel,
          ),
          const Divider(height: 1),
          _CoverageInformationRow(package: package),
          const Divider(height: 1),
          _IconDataRow(
            icon: Icons.autorenew_rounded,
            label: 'Renewal',
            value: package.renewalLabel,
          ),
          const Divider(height: 1),
          _IconDataRow(
            icon: Icons.phone_in_talk_outlined,
            label: 'Voice / SMS',
            value: package.voiceSmsLabel,
          ),
        ],
      ),
    );
  }
}

class _CoverageInformationRow extends StatelessWidget {
  const _CoverageInformationRow({required this.package});

  final MobilePackage package;

  @override
  Widget build(BuildContext context) {
    const previewLimit = 7;
    final countries = package.supportedCountries;
    final visible = countries.take(previewLimit).toList(growable: false);
    final remaining = countries.length - visible.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.language_rounded,
            size: 20,
            color: Color(0xFF475569),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Coverage',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  package.destination,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (visible.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final country in visible)
                        PackageDestinationVisual(
                          code: country.code,
                          destinationKey: '',
                          size: 26,
                        ),
                      if (remaining > 0) _CountBadge(count: remaining),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportantNotesCard extends StatelessWidget {
  const _ImportantNotesCard({required this.package, required this.isPhysical});

  final MobilePackage package;
  final bool isPhysical;

  @override
  Widget build(BuildContext context) {
    final voiceSmsIncluded =
        package.voiceSmsLabel.trim().toLowerCase() == 'included';

    return _DetailCard(
      title: 'Important notes',
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF6D98B)),
        ),
        child: Column(
          children: [
            if (!voiceSmsIncluded) ...[
              const _NoteLine(
                icon: Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                text:
                    'This is a data-only plan. Voice calls and SMS are not included.',
              ),
              const Divider(height: 24),
            ],
            _NoteLine(
              icon: Icons.info_outline_rounded,
              color: AppColors.primary,
              text: isPhysical
                  ? 'The physical SIM identifier may be required during checkout.'
                  : 'Installation details become available after provisioning.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
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
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF334155)),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F8E9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Live',
        style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IconDataRow extends StatelessWidget {
  const _IconDataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF475569)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.45),
          ),
        ),
      ],
    );
  }
}
