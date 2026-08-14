import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'package_catalog.dart';
import 'packages_repository.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final _repository = PackagesRepository();
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
  final _validityOptions = const [30, 60, 90];
  final _dataOptions = const [1, 3, 5, 10, 20, 30, 50, 60, 100, 135, 200, 300, 400, 500];

  Timer? _searchTimer;
  List<MobilePackage> _packages = const [];
  String _selectedType = '';
  String _selectedOperator = '';
  int? _selectedValidity;
  num? _selectedData;
  bool _loading = true;
  bool _showingStaleData = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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
      final catalog = await _repository.fetchPackages(forceRefresh: forceRefresh);
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
    return _packages.where((item) {
      if (_selectedOperator.isNotEmpty && item.operatorKey != _selectedOperator) return false;
      if (_selectedType.isNotEmpty && item.packageType.toLowerCase() != _selectedType) return false;
      if (_selectedValidity != null && item.validityDays != _selectedValidity) return false;
      if (_selectedData != null && item.dataGb != _selectedData) return false;
      if (term.isNotEmpty && ![
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
    }).toList(growable: false);
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedType = '';
      _selectedOperator = '';
      _selectedValidity = null;
      _selectedData = null;
    });
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
              _CatalogFilterPanel(
                operators: _operators,
                validityOptions: _validityOptions,
                dataOptions: _dataOptions,
                operator: _selectedOperator,
                type: _selectedType,
                validity: _selectedValidity,
                data: _selectedData,
                searchController: _searchController,
                onOperatorChanged: (value) => setState(() => _selectedOperator = value),
                onTypeChanged: (value) => setState(() => _selectedType = value),
                onValidityChanged: (value) => setState(() => _selectedValidity = value),
                onDataChanged: (value) => setState(() => _selectedData = value),
                onSearchChanged: _onSearchChanged,
              ),
              const SizedBox(height: 18),
              _CatalogSection(
                title: 'Available Plans',
                trailing: '${visible.length} plans',
                child: _buildCatalogContent(visible),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogContent(List<MobilePackage> visible) {
    if (_loading) return const ContentLoadingState(label: 'Loading packages...');
    if (_error != null && _packages.isEmpty) {
      return ContentErrorState(message: _error!, onRetry: () => _load(forceRefresh: true));
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
        for (var index = 0; index < visible.length; index++) ...[
          _OperatorPlanCard(
            package: visible[index],
            onTap: () => context.push('/packages/detail', extra: visible[index]),
          ),
          if (index != visible.length - 1) const SizedBox(height: 12),
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
        boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
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
            child: const Icon(Icons.public_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unified Operator Catalog', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Multi-provider eSIM inventory with smart routing', style: theme.textTheme.bodySmall),
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
  const _CatalogSection({required this.title, required this.trailing, required this.child});

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
        boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                child: Text(trailing, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
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

class _CatalogFilterPanel extends StatelessWidget {
  const _CatalogFilterPanel({
    required this.operators,
    required this.validityOptions,
    required this.dataOptions,
    required this.operator,
    required this.type,
    required this.validity,
    required this.data,
    required this.searchController,
    required this.onOperatorChanged,
    required this.onTypeChanged,
    required this.onValidityChanged,
    required this.onDataChanged,
    required this.onSearchChanged,
  });

  final List<(String, String)> operators;
  final List<int> validityOptions;
  final List<num> dataOptions;
  final String operator;
  final String type;
  final int? validity;
  final num? data;
  final TextEditingController searchController;
  final ValueChanged<String> onOperatorChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int?> onValidityChanged;
  final ValueChanged<num?> onDataChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Catalog filters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Filter by operator, product type, validity, data and plan name.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          _FilterField(
            label: 'Operator',
            child: DropdownButtonFormField<String>(
              key: ValueKey(operator),
              initialValue: operator,
              isExpanded: true,
              items: operators.map((item) => DropdownMenuItem(value: item.$2, child: Text(item.$1))).toList(),
              onChanged: (value) => onOperatorChanged(value ?? ''),
            ),
          ),
          const SizedBox(height: 12),
          _FilterField(
            label: 'Type',
            child: DropdownButtonFormField<String>(
              key: ValueKey(type),
              initialValue: type,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: '', child: Text('All Types')),
                DropdownMenuItem(value: 'esim', child: Text('eSIM')),
                DropdownMenuItem(value: 'simcard', child: Text('SIM Card')),
              ],
              onChanged: (value) => onTypeChanged(value ?? ''),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FilterField(
                  label: 'Validity',
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('validity-$validity'),
                    initialValue: validity?.toString() ?? '',
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All')),
                      ...validityOptions.map((item) => DropdownMenuItem(value: '$item', child: Text('$item Days'))),
                    ],
                    onChanged: (value) => onValidityChanged(int.tryParse(value ?? '')),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterField(
                  label: 'Data',
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('data-$data'),
                    initialValue: data?.toString() ?? '',
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All')),
                      ...dataOptions.map((item) => DropdownMenuItem(value: '$item', child: Text('${item}GB'))),
                    ],
                    onChanged: (value) => onDataChanged(num.tryParse(value ?? '')),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterField(
            label: 'Search',
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(hintText: 'Search', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: .7)),
          const SizedBox(height: 6),
          child,
        ],
      );
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
            Expanded(child: Text('Could not refresh. Showing the last available packages.', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class _OperatorPlanCard extends StatelessWidget {
  const _OperatorPlanCard({required this.package, required this.onTap});

  final MobilePackage package;
  final VoidCallback onTap;

  Color get _accent {
    switch (package.operatorKey) {
      case 'vodafone':
        return AppColors.vodafone;
      case 'turkey':
        return AppColors.danger;
      case 'orange-world':
      case 'worldmove':
        return AppColors.orange;
      case 'kpn':
        return AppColors.violet;
      case 'flexnet':
        return AppColors.primary;
      case 'orange-balkans':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manual = package.provider.toLowerCase() == 'manual';
    final accent = _accent;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: .28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      package.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                    child: _CountryVisual(
                      code: package.countryCode,
                      destinationKey: package.destinationKey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      manual ? '${package.displayProvider} · manual delivery' : package.displayProvider,
                      style: theme.textTheme.bodySmall?.copyWith(color: accent, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              if (package.supportedCountries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Supported countries', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w900, letterSpacing: .4)),
                const SizedBox(height: 7),
                _CoveragePreview(countries: package.supportedCountries, accent: accent),
              ],
              const SizedBox(height: 14),
              _PlanDetailRow(label: 'Region', value: package.destination),
              _PlanDetailRow(label: 'Type', value: package.packageType == 'simcard' ? 'SIM Card' : 'eSIM'),
              _PlanDetailRow(label: 'Data', value: package.dataLabel),
              _PlanDetailRow(label: 'Validity', value: package.validityLabel),
              _PlanDetailRow(label: 'Price', value: package.formattedPrice, emphasize: true),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: Text(manual ? 'Review request' : 'View plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanDetailRow extends StatelessWidget {
  const _PlanDetailRow({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: emphasize ? AppColors.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoveragePreview extends StatelessWidget {
  const _CoveragePreview({required this.countries, required this.accent});
  final List<PackageCountry> countries;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const previewLimit = 8;
    final visible = countries.take(previewLimit).toList(growable: false);
    final remaining = countries.length - visible.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final country in visible)
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: .20)),
            ),
            child: _CountryVisual(
              code: country.code,
              destinationKey: country.code == 'EU' ? 'europe' : '',
              compact: true,
            ),
          ),
        if (remaining > 0)
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Text(
              '+$remaining',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
      ],
    );
  }
}

class _CountryVisual extends StatelessWidget {
  const _CountryVisual({required this.code, required this.destinationKey, this.compact = false});
  final String code;
  final String destinationKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalizedCode = code.toUpperCase();
    final isEurope = destinationKey.toLowerCase() == 'europe' || normalizedCode == 'EU';
    final url = isEurope
        ? 'https://flagcdn.com/w160/eu.png'
        : normalizedCode.length == 2
            ? 'https://flagcdn.com/w40/${normalizedCode.toLowerCase()}.png'
            : null;
    if (url == null) return Icon(Icons.public_rounded, color: AppColors.primary, size: compact ? 18 : 27);
    final size = compact ? 26.0 : 36.0;
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.public_rounded, color: AppColors.primary, size: compact ? 18 : 27),
      ),
    );
  }
}
