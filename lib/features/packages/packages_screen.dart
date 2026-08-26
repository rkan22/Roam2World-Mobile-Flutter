import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/routing/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/package_destination_visual.dart';
import '../../shared/widgets/package_type_chip.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import '../../shared/widgets/staggered_entrance.dart';
import '../auth/auth_repository.dart';
import 'package_catalog.dart';
import 'packages_repository.dart';
import 'widgets/catalog_filter_sheet.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final _repository = PackagesRepository();
  final _authRepository = AuthRepository();
  final _searchController = TextEditingController();
  final _operators = const [
    ('All Operators', ''),
    ('Vodafone', 'vodafone'),
    ('Orange Europe', 'worldmove'),
    ('Orange World', 'orange-world'),
    ('KPN Europe', 'kpn'),
    ('T.T Turkey', 'turkey'),
    ('Orange Big Data', 'flexnet'),
    ('Orange Balkans', 'orange-balkans'),
    ('Manual Fulfillment', 'manual'),
  ];

  Timer? _searchTimer;
  List<MobilePackage> _packages = const [];
  CatalogFilterSelection _filters = const CatalogFilterSelection();
  bool _loading = true;
  bool _showingStaleData = false;
  String? _error;
  AppRole _role = AppRole.unknown;

  @override
  void initState() {
    super.initState();
    PackagesRepository.catalogRevision.addListener(_onCatalogInvalidated);
    _loadRole();
    _load();
  }

  Future<void> _loadRole() async {
    final profile = await _authRepository.readStoredProfile();
    if (!mounted) return;
    setState(() => _role = parseAppRole(profile?.role));
  }

  void _onCatalogInvalidated() {
    if (mounted) _load(forceRefresh: true);
  }

  @override
  void dispose() {
    PackagesRepository.catalogRevision.removeListener(_onCatalogInvalidated);
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = _packages.isEmpty;
      _error = null;
    });
    try {
      final catalog = await _repository.fetchPackages(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _packages = catalog.packages;
        _showingStaleData = _repository.lastFetchUsedStale;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Packages could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MobilePackage> get _visiblePackages {
    final term = _searchController.text.trim().toLowerCase();
    return _packages
        .where((item) {
          if (_filters.operatorKey.isNotEmpty &&
              item.operatorKey != _filters.operatorKey) {
            return false;
          }
          if (_filters.packageType.isNotEmpty &&
              item.packageType.toLowerCase() != _filters.packageType) {
            return false;
          }
          if (_filters.countryCode.isNotEmpty &&
              item.countryCode.toUpperCase() !=
                  _filters.countryCode.toUpperCase() &&
              !item.supportedCountries.any(
                (country) =>
                    country.code.toUpperCase() ==
                    _filters.countryCode.toUpperCase(),
              )) {
            return false;
          }
          if (!matchesValidityRange(
            item.validityDays,
            _filters.validityRange,
          )) {
            return false;
          }
          if (!matchesDataRange(item.dataGb, _filters.dataRange)) {
            return false;
          }
          if (term.isNotEmpty &&
              ![
                item.name,
                item.destination,
                item.displayProvider,
                item.provider,
                item.id,
                item.dataLabel,
                item.validityLabel,
              ].any((value) => value.toLowerCase().contains(term))) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _filters = const CatalogFilterSelection());
  }

  List<PackageCountry> get _countryOptions {
    final countries = <String, PackageCountry>{};

    for (final package in _packages) {
      for (final country in package.supportedCountries) {
        final code = country.code.trim().toUpperCase();
        if (code.isEmpty) continue;
        countries.putIfAbsent(
          code,
          () => PackageCountry(
            name: country.name.trim().isEmpty ? code : country.name,
            code: code,
          ),
        );
      }
    }

    final result = countries.values.toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  String get _selectedOperatorLabel {
    for (final item in _operators) {
      if (item.$2 == _filters.operatorKey) return item.$1;
    }
    return _filters.operatorKey;
  }

  String get _selectedCountryLabel {
    for (final country in _countryOptions) {
      if (country.code == _filters.countryCode) return country.name;
    }
    return _filters.countryCode;
  }

  Future<void> _showCatalogFilters() async {
    final selected = await showCatalogFilterSheet(
      context,
      initialSelection: _filters,
      operators: _operators,
      countries: _countryOptions,
    );

    if (!mounted || selected == null) return;
    setState(() => _filters = selected);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visiblePackages;
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              if (_showingStaleData) ...[
                const _StaleDataBanner(),
                const SizedBox(height: 14),
              ],
              const _CatalogHero(),
              const SizedBox(height: 18),
              CatalogFilterToolbar(
                searchController: _searchController,
                selection: _filters,
                operatorLabel: _selectedOperatorLabel,
                countryLabel: _selectedCountryLabel,
                onSearchChanged: _onSearchChanged,
                onFiltersPressed: _showCatalogFilters,
                onClearAll: _clearFilters,
              ),
              const SizedBox(height: 18),
              _CatalogSection(
                title: 'Available Plans',
                trailing: '${visible.length} plans',
                child: AnimatedSwitcher(
                  duration: B2BMotion.standard,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offset = Tween<Offset>(
                      begin: const Offset(0, .025),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(
                      '${_loading}_${_filters.operatorKey}_'
                      '${_filters.packageType}_${_filters.countryCode}_'
                      '${_filters.validityRange}_${_filters.dataRange}_'
                      '${_searchController.text}_${visible.length}',
                    ),
                    child: _buildCatalogContent(visible),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogContent(List<MobilePackage> visible) {
    if (_loading) {
      return const ContentLoadingState(label: 'Loading packages...');
    }
    if (_error != null && _packages.isEmpty) {
      return ContentErrorState(
        message: _error!,
        onRetry: () => _load(forceRefresh: true),
      );
    }
    if (visible.isEmpty) {
      return ContentEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No packages found',
        message: 'Try changing or clearing the catalog filters.',
        actionLabel: 'Clear filters',
        onAction: _clearFilters,
      );
    }
    return Column(
      children: [
        _LiveCatalogBanner(count: visible.length),
        const SizedBox(height: 14),
        for (var index = 0; index < visible.length; index++) ...[
          StaggeredEntrance(
            key: ValueKey('${visible[index].provider}-${visible[index].id}'),
            index: index,
            child: _OperatorPlanCard(
              package: visible[index],
              isAdmin: _role == AppRole.admin,
              onTap: () =>
                  context.push('/packages/detail', extra: visible[index]),
            ),
          ),
          if (index != visible.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySoft, AppColors.accentSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: theme.brightness == Brightness.light
            ? B2BShadows.card
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.public_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unified Operator Catalog',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Multi-provider eSIM inventory with smart routing',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String title;
  final String trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trailing,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StaleDataBanner extends StatelessWidget {
  const _StaleDataBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.warning.withValues(alpha: .4)),
    ),
    child: const Row(
      children: [
        Icon(Icons.cloud_off_rounded, size: 19, color: AppColors.warning),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Could not refresh. Showing the last available packages.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _LiveCatalogBanner extends StatelessWidget {
  const _LiveCatalogBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Only live plans are shown in the catalog.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary),
            ),
            child: Text(
              '$count live ${count == 1 ? 'plan' : 'plans'}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorPlanCard extends StatelessWidget {
  const _OperatorPlanCard({
    required this.package,
    required this.isAdmin,
    required this.onTap,
  });

  final MobilePackage package;
  final bool isAdmin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manual = package.provider.trim().toLowerCase() == 'manual';
    final typeLabel = package.packageType == 'simcard' ? 'SIM Card' : 'eSIM';
    final providerLabel = package.displayProvider.trim();

    return B2BSurface(
      onTap: package.isPriceAvailable || isAdmin ? onTap : null,
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PackageTypeChip(
                packageType: package.packageType,
                size: 42,
                iconSize: 23,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  package.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Live',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (providerLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              manual ? '$providerLabel · Manual Delivery' : providerLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                typeLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),
              Text(
                package.isPriceAvailable
                    ? package.formattedPrice
                    : isAdmin
                    ? 'Pricing rule required'
                    : 'Contact Admin',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: package.isPriceAvailable
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (package.supportedCountries.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CoveragePreview(countries: package.supportedCountries),
          ],
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _CompactPlanMetric(
                      icon: package.packageType == 'simcard'
                          ? Icons.sim_card_outlined
                          : Icons.memory_rounded,
                      label: 'Type',
                      value: typeLabel,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _CompactPlanMetric(
                      icon: Icons.storage_rounded,
                      label: 'Data',
                      value: package.dataLabel,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _CompactPlanMetric(
                      icon: Icons.calendar_month_outlined,
                      label: 'Validity',
                      value: package.validityLabel,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _CompactPlanMetric(
                      icon: Icons.sell_outlined,
                      label: 'Price',
                      value: package.isPriceAvailable
                          ? package.formattedPrice
                          : 'Request',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactPlanMetric extends StatelessWidget {
  const _CompactPlanMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoveragePreview extends StatelessWidget {
  const _CoveragePreview({required this.countries});
  final List<PackageCountry> countries;

  @override
  Widget build(BuildContext context) {
    const previewLimit = 8;
    final visible = countries.take(previewLimit).toList(growable: false);
    final remaining = countries.length - visible.length;

    return SizedBox(
      height: 30,
      child: Row(
        children: [
          for (var index = 0; index < visible.length; index++) ...[
            if (index > 0) const SizedBox(width: 2),
            PackageDestinationVisual(
              code: visible[index].code,
              destinationKey: visible[index].code == 'EU' ? 'europe' : '',
              size: 28,
            ),
          ],
          if (remaining > 0) ...[
            const SizedBox(width: 8),
            Text(
              '+$remaining',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
