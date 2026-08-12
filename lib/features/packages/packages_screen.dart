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
    ('Movistar', 'movistar'),
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
      ].any((value) => value.toLowerCase().contains(term))) return false;
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
    final theme = Theme.of(context);
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('eSIM Marketplace', style: theme.textTheme.headlineLarge),
                        const SizedBox(height: 5),
                        Text('Choose the right plan for your customer in seconds.', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: B2BGradients.primary,
                  borderRadius: BorderRadius.circular(B2BRadius.xl),
                  boxShadow: B2BShadows.card,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.public_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Global coverage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('Compare operators and choose a package.', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search destination, operator or package',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(onPressed: _clearFilters, icon: const Icon(Icons.clear_rounded)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _operators.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final operator = _operators[index];
                    final selected = _selectedOperator == operator.$2;
                    return ChoiceChip(
                      label: Text(operator.$1),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedOperator = operator.$2),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              if (_error != null)
                ErrorState(
                  message: _error!,
                  onRetry: _load,
                )
              else if (_loading)
                const LoadingState()
              else if (visible.isEmpty)
                EmptyState(
                  title: 'No packages found',
                  message: 'Try another operator, destination or data amount.',
                  actionLabel: 'Clear filters',
                  onAction: _clearFilters,
                )
              else
                ...visible.map(
                  (package) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PackageTile(
                      package: package,
                      onTap: () => context.push('/packages/${Uri.encodeComponent(package.id)}'),
                    ),
                  ),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Showing cached catalog data. Pull to refresh.')),
          ],
        ),
      );
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package, required this.onTap});
  final MobilePackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(B2BRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(B2BRadius.xl),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 54,
                    width: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: _CountryVisual(
                      code: package.countryCode,
                      destinationKey: package.destinationKey,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(package.destination, style: theme.textTheme.titleMedium?.copyWith(fontSize: 16.5)),
                        const SizedBox(height: 3),
                        Text(package.displayProvider, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    package.formattedPrice,
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary, fontSize: 17),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(child: _InlineMetric(icon: Icons.data_usage_rounded, value: package.dataLabel)),
                    Container(width: 1, height: 26, color: AppColors.border),
                    Expanded(child: _InlineMetric(icon: Icons.schedule_rounded, value: package.validityLabel)),
                    Container(width: 1, height: 26, color: AppColors.border),
                    const Expanded(child: _InlineMetric(icon: Icons.network_cell_rounded, value: '4G / 5G')),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Reseller-ready plan', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(92, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('View plan'),
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

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ),
        ],
      );
}

class _CountryVisual extends StatelessWidget {
  const _CountryVisual({required this.code, required this.destinationKey});
  final String code;
  final String destinationKey;

  @override
  Widget build(BuildContext context) {
    if (destinationKey.toLowerCase() == 'europe') {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          'assets/catalog/europe.png',
          width: 42,
          height: 42,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.public_rounded,
            color: AppColors.primary,
            size: 27,
          ),
        ),
      );
    }
    if (code.length != 2) {
      return const Icon(Icons.public_rounded, color: AppColors.primary, size: 27);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        'https://flagsapi.com/${code.toUpperCase()}/flat/64.png',
        width: 34,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.public_rounded,
          color: AppColors.primary,
          size: 27,
        ),
      ),
    );
  }
}
