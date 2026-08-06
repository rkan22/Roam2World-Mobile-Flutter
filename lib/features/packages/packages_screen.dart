import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
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
                children: [
                  const Expanded(
                    child: Text('Packages', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search countries or packages',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 22),
              const Text('Destinations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              SizedBox(
                height: 78,
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
              const SizedBox(height: 20),
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
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 48,
              width: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Text(flag, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 6),
            Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? AppColors.primary : null)),
          ],
        ),
      );
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package, required this.onTap});
  final MobilePackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(17)),
                  child: Text(_flagFor(package.countryCode), style: const TextStyle(fontSize: 27)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(package.destination, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(package.displayProvider, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.data_usage_rounded, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(child: Text(package.dataLabel, style: const TextStyle(fontWeight: FontWeight.w800))),
                          const SizedBox(width: 12),
                          const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(child: Text(package.validityLabel, style: const TextStyle(fontWeight: FontWeight.w800))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(package.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(minimumSize: const Size(72, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                      child: const Text('Buy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

String _flagFor(String code) {
  if (code.length != 2) return '🌐';
  return code.toUpperCase().codeUnits.map((unit) => String.fromCharCode(unit + 127397)).join();
}
