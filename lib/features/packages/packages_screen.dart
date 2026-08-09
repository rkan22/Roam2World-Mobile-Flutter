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
  final _filters = const ['All', 'Data', 'Voice', 'Data + Voice'];
  final _destinations = const [
    ('🌐', 'All', ''),
    ('🇹🇷', 'Turkey', 'turkey'),
    ('🇪🇺', 'Europe', 'europe'),
    ('🌍', 'Global', 'global'),
  ];

  Timer? _searchTimer;
  List<MobilePackage> _packages = const [];
  int _selectedFilter = 0;
  int _selectedDestination = 0;
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
      final catalog = await _repository.fetchPackages(
        search: _searchController.text,
        destination: _destinations[_selectedDestination].$3,
        packageType: _packageType,
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

  String? get _packageType => switch (_selectedFilter) {
        1 => 'DATA-ONLY',
        2 => 'VOICE',
        3 => 'DATA-VOICE',
        _ => null,
      };

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 450), _load);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                        Text(
                          'Choose the right plan for your customer in seconds.',
                          style: theme.textTheme.bodyMedium,
                        ),
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
                          Text('Global coverage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Search local, regional and global reseller plans.', style: TextStyle(color: Colors.white70, height: 1.35)),
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
                  hintText: 'Search country, region or package',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _load();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle(title: 'Destinations', trailing: '${_packages.length} plans'),
              const SizedBox(height: 12),
              SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _destinations.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _destinations[index];
                    return _Country(
                      flag: item.$1,
                      name: item.$2,
                      selected: _selectedDestination == index,
                      onTap: () {
                        setState(() => _selectedDestination = index);
                        _load();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ChoiceChip(
                    label: Text(_filters[index]),
                    selected: _selectedFilter == index,
                    onSelected: (_) {
                      setState(() => _selectedFilter = index);
                      _load();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const ContentLoadingState(label: 'Loading packages...')
              else if (_error != null && _packages.isEmpty)
                ContentErrorState(message: _error!, onRetry: () => _load(forceRefresh: true))
              else if (_packages.isEmpty)
                ContentEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No packages found',
                  message: 'Try another search or destination.',
                  actionLabel: 'Clear filters',
                  onAction: () {
                    _searchController.clear();
                    setState(() {
                      _selectedFilter = 0;
                      _selectedDestination = 0;
                    });
                    _load();
                  },
                )
              else
                for (var index = 0; index < _packages.length; index++) ...[
                  _PackageTile(
                    package: _packages[index],
                    onTap: () => context.push('/packages/detail', extra: _packages[index]),
                  ),
                  if (index != _packages.length - 1) const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          Text(trailing, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
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

class _Country extends StatelessWidget {
  const _Country({required this.flag, required this.name, required this.selected, required this.onTap});
  final String flag;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 54,
              width: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? AppColors.primary : theme.colorScheme.outlineVariant),
                boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
              ),
              child: Text(flag, style: const TextStyle(fontSize: 25)),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? AppColors.primary : null),
            ),
          ],
        ),
      ),
    );
  }
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
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(17)),
                    child: Text(_flagFor(package.countryCode), style: const TextStyle(fontSize: 27)),
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
                  Text(package.formattedPrice, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary, fontSize: 17)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(16)),
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
                    style: FilledButton.styleFrom(minimumSize: const Size(92, 40), padding: const EdgeInsets.symmetric(horizontal: 16)),
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
          Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
        ],
      );
}

String _flagFor(String code) {
  if (code.length != 2) return '🌐';
  return code.toUpperCase().codeUnits.map((unit) => String.fromCharCode(unit + 127397)).join();
}
