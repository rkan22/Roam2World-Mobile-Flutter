import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
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
  final _destinations = const [
    ('🌐', 'All', ''),
    ('🇹🇷', 'Turkey', 'turkey'),
    ('🇪🇺', 'Europe', 'europe'),
    ('🌍', 'Global', 'global'),
  ];

  Timer? _searchTimer;
  List<MobilePackage> _packages = const [];
  int _selectedDestination = 0;
  String? _provider;
  String? _productKind;
  int? _validityDays;
  double? _dataGb;
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

  int get _activeFilterCount => [
        _provider,
        _productKind,
        _validityDays,
        _dataGb,
      ].where((value) => value != null).length;

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = _packages.isEmpty;
      _error = null;
    });
    try {
      final catalog = await _repository.fetchPackages(
        search: _searchController.text,
        destination: _destinations[_selectedDestination].$3,
        provider: _provider,
        productKind: _productKind,
        validityDays: _validityDays,
        dataGb: _dataGb,
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
      setState(() => _error = 'Catalog could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 420), _load);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_CatalogFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CatalogFilterSheet(
        current: _CatalogFilters(
          provider: _provider,
          productKind: _productKind,
          validityDays: _validityDays,
          dataGb: _dataGb,
        ),
        providers: _providerOptions,
      ),
    );
    if (result == null) return;
    setState(() {
      _provider = result.provider;
      _productKind = result.productKind;
      _validityDays = result.validityDays;
      _dataGb = result.dataGb;
    });
    await _load();
  }

  List<String> get _providerOptions {
    final seen = <String>{};
    final values = <String>[];
    for (final package in _packages) {
      final value = package.displayProvider.trim();
      if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
      values.add(value);
    }
    values.sort();
    return values;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedDestination = 0;
      _provider = null;
      _productKind = null;
      _validityDays = null;
      _dataGb = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              B2BSpacing.lg,
              B2BSpacing.md,
              B2BSpacing.lg,
              B2BSpacing.xxl,
            ),
            children: [
              if (_showingStaleData) ...[
                const _StaleDataBanner(),
                const SizedBox(height: B2BSpacing.md),
              ],
              _CatalogHeader(
                onNotificationsTap: () => context.push('/notifications'),
              ),
              const SizedBox(height: B2BSpacing.lg),
              _SearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                filterCount: _activeFilterCount,
                onFilterTap: _openFilters,
              ),
              const SizedBox(height: B2BSpacing.lg),
              _DestinationStrip(
                destinations: _destinations,
                selectedIndex: _selectedDestination,
                onSelected: (index) {
                  setState(() => _selectedDestination = index);
                  _load();
                },
              ),
              if (_activeFilterCount > 0) ...[
                const SizedBox(height: B2BSpacing.md),
                _ActiveFilters(
                  provider: _provider,
                  productKind: _productKind,
                  validityDays: _validityDays,
                  dataGb: _dataGb,
                  onClear: _clearFilters,
                ),
              ],
              const SizedBox(height: B2BSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Unified catalog',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Text(
                    '${_packages.length} plans',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.md),
              if (_loading)
                const ContentLoadingState(label: 'Loading unified catalog...')
              else if (_error != null && _packages.isEmpty)
                ContentErrorState(
                  message: _error!,
                  onRetry: () => _load(forceRefresh: true),
                )
              else if (_packages.isEmpty)
                ContentEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No plans found',
                  message: 'Try another destination or remove some filters.',
                  actionLabel: 'Clear filters',
                  onAction: _clearFilters,
                )
              else
                for (var index = 0; index < _packages.length; index++) ...[
                  _PackageCard(
                    package: _packages[index],
                    onTap: () => context.push(
                      '/packages/detail',
                      extra: _packages[index],
                    ),
                  ),
                  if (index != _packages.length - 1)
                    const SizedBox(height: B2BSpacing.md),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catalog',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: B2BSpacing.xs),
              Text(
                'Compare SIM & eSIM inventory across providers.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onNotificationsTap,
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.filterCount,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int filterCount;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search plans, countries, providers',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(width: B2BSpacing.sm),
        Badge(
          isLabelVisible: filterCount > 0,
          label: Text('$filterCount'),
          child: IconButton.filledTonal(
            onPressed: onFilterTap,
            tooltip: 'Catalog filters',
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}

class _DestinationStrip extends StatelessWidget {
  const _DestinationStrip({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<(String, String, String)> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: destinations.length,
        separatorBuilder: (_, _) => const SizedBox(width: B2BSpacing.sm),
        itemBuilder: (context, index) {
          final item = destinations[index];
          return ChoiceChip(
            avatar: Text(item.$1),
            label: Text(item.$2),
            selected: selectedIndex == index,
            onSelected: (_) => onSelected(index),
          );
        },
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    this.provider,
    this.productKind,
    this.validityDays,
    this.dataGb,
    required this.onClear,
  });

  final String? provider;
  final String? productKind;
  final int? validityDays;
  final double? dataGb;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (provider != null) provider!,
      if (productKind != null) productKind!,
      if (validityDays != null) '$validityDays days',
      if (dataGb != null) '${dataGb!.toStringAsFixed(dataGb! % 1 == 0 ? 0 : 1)} GB',
    ];
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final label in labels) ...[
                  Chip(label: Text(label)),
                  const SizedBox(width: B2BSpacing.xs),
                ],
              ],
            ),
          ),
        ),
        TextButton(onPressed: onClear, child: const Text('Clear')),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, required this.onTap});

  final MobilePackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: Text(
                  _flagFor(package.countryCode),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: B2BSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            package.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        if (package.isFeatured)
                          const Padding(
                            padding: EdgeInsets.only(left: B2BSpacing.xs),
                            child: Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: B2BSpacing.xs),
                    Text(
                      '${package.displayProvider} · ${package.productKind}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          Wrap(
            spacing: B2BSpacing.xs,
            runSpacing: B2BSpacing.xs,
            children: [
              _SpecChip(icon: Icons.data_usage_rounded, label: package.dataLabel),
              _SpecChip(icon: Icons.schedule_rounded, label: package.validityLabel),
              _SpecChip(icon: Icons.public_rounded, label: package.destination),
              if (package.coverageCount > 1)
                _SpecChip(
                  icon: Icons.language_rounded,
                  label: '${package.coverageCount} countries',
                ),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'B2B price',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      package.formattedPrice,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('View plan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(B2BRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: B2BSpacing.sm,
          vertical: B2BSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogFilters {
  const _CatalogFilters({
    this.provider,
    this.productKind,
    this.validityDays,
    this.dataGb,
  });

  final String? provider;
  final String? productKind;
  final int? validityDays;
  final double? dataGb;
}

class _CatalogFilterSheet extends StatefulWidget {
  const _CatalogFilterSheet({required this.current, required this.providers});

  final _CatalogFilters current;
  final List<String> providers;

  @override
  State<_CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<_CatalogFilterSheet> {
  static const _all = '__all__';
  String? _provider;
  String? _productKind;
  int? _validityDays;
  double? _dataGb;

  @override
  void initState() {
    super.initState();
    _provider = widget.current.provider;
    _productKind = widget.current.productKind;
    _validityDays = widget.current.validityDays;
    _dataGb = widget.current.dataGb;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(B2BRadius.xl)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          B2BSpacing.lg,
          B2BSpacing.lg,
          B2BSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + B2BSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Catalog filters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.xs),
              Text(
                'Filter by operator, product type, validity and data.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: B2BSpacing.xl),
              DropdownButtonFormField<String>(
                value: _provider ?? _all,
                decoration: const InputDecoration(labelText: 'Operator'),
                items: [
                  const DropdownMenuItem(value: _all, child: Text('All operators')),
                  for (final provider in widget.providers)
                    DropdownMenuItem(value: provider, child: Text(provider)),
                ],
                onChanged: (value) => setState(
                  () => _provider = value == _all ? null : value,
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              DropdownButtonFormField<String>(
                value: _productKind ?? _all,
                decoration: const InputDecoration(labelText: 'Product type'),
                items: const [
                  DropdownMenuItem(value: _all, child: Text('All types')),
                  DropdownMenuItem(value: 'eSIM', child: Text('eSIM')),
                  DropdownMenuItem(value: 'SIM Card', child: Text('SIM Card')),
                ],
                onChanged: (value) => setState(
                  () => _productKind = value == _all ? null : value,
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              DropdownButtonFormField<int>(
                value: _validityDays ?? 0,
                decoration: const InputDecoration(labelText: 'Validity'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Any validity')),
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 15, child: Text('15 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                  DropdownMenuItem(value: 60, child: Text('60 days')),
                  DropdownMenuItem(value: 90, child: Text('90 days')),
                ],
                onChanged: (value) => setState(
                  () => _validityDays = value == 0 ? null : value,
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              DropdownButtonFormField<double>(
                value: _dataGb ?? 0,
                decoration: const InputDecoration(labelText: 'Data'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Any data')),
                  DropdownMenuItem(value: 1, child: Text('1 GB')),
                  DropdownMenuItem(value: 3, child: Text('3 GB')),
                  DropdownMenuItem(value: 5, child: Text('5 GB')),
                  DropdownMenuItem(value: 10, child: Text('10 GB')),
                  DropdownMenuItem(value: 20, child: Text('20 GB')),
                  DropdownMenuItem(value: 50, child: Text('50 GB')),
                ],
                onChanged: (value) => setState(
                  () => _dataGb = value == 0 ? null : value,
                ),
              ),
              const SizedBox(height: B2BSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _provider = null;
                          _productKind = null;
                          _validityDays = null;
                          _dataGb = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _CatalogFilters(
                          provider: _provider,
                          productKind: _productKind,
                          validityDays: _validityDays,
                          dataGb: _dataGb,
                        ),
                      ),
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaleDataBanner extends StatelessWidget {
  const _StaleDataBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: B2BSpacing.md,
          vertical: B2BSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(B2BRadius.md),
          border: Border.all(color: AppColors.warning.withValues(alpha: .4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 19, color: AppColors.warning),
            SizedBox(width: B2BSpacing.sm),
            Expanded(
              child: Text(
                'Could not refresh. Showing the last available catalog.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

String _flagFor(String code) {
  if (code.length != 2) return '🌐';
  return code
      .toUpperCase()
      .codeUnits
      .map((unit) => String.fromCharCode(unit + 127397))
      .join();
}
