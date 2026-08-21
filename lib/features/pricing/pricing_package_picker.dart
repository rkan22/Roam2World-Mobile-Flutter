import 'package:flutter/material.dart';

import '../packages/package_catalog.dart';
import '../packages/packages_repository.dart';

class PricingPackageSelection {
  const PricingPackageSelection.package(this.package) : allPackages = false;
  const PricingPackageSelection.all() : package = null, allPackages = true;

  final MobilePackage? package;
  final bool allPackages;
}

Future<PricingPackageSelection?> showPricingPackagePicker({
  required BuildContext context,
  required String provider,
  required PackagesRepository repository,
  ValueChanged<List<MobilePackage>>? onCatalogLoaded,
}) {
  return showModalBottomSheet<PricingPackageSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PricingPackagePicker(
      provider: provider,
      repository: repository,
      onCatalogLoaded: onCatalogLoaded,
    ),
  );
}

class _PricingPackagePicker extends StatefulWidget {
  const _PricingPackagePicker({
    required this.provider,
    required this.repository,
    this.onCatalogLoaded,
  });

  final String provider;
  final PackagesRepository repository;
  final ValueChanged<List<MobilePackage>>? onCatalogLoaded;

  @override
  State<_PricingPackagePicker> createState() => _PricingPackagePickerState();
}

class _PricingPackagePickerState extends State<_PricingPackagePicker> {
  final _searchController = TextEditingController();

  List<MobilePackage> _packages = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final catalog = await widget.repository.fetchPackages();
      final packages =
          catalog.packages
              .where((item) => _matchesProvider(item, widget.provider))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      widget.onCatalogLoaded?.call(packages);

      if (!mounted) return;
      setState(() => _packages = packages);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Package catalog could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _matchesProvider(MobilePackage item, String provider) {
    final selected = provider.trim().toLowerCase();
    final source = item.provider.trim().toLowerCase();

    // Manual Fulfillment is its own operator. It must never leak into
    // another operator's package picker.
    if (selected == 'manual') return source == 'manual';
    if (source == 'manual') return false;

    // For providers represented by a dedicated operator key, prefer the
    // normalized operator identity so T.T Turkey/KPN/Orange families remain
    // separated even though they share the Worldmove source.
    if (item.operatorKey == selected) return true;

    return source == selected;
  }

  List<MobilePackage> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _packages;

    return _packages.where((item) {
      return [
        item.name,
        item.id,
        item.destination,
        item.dataLabel,
        item.validityLabel,
        item.displayProvider,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select package',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Search packages',
                  hintText: 'Package name, ID, country, data...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.layers_outlined)),
              title: const Text(
                'All packages',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Apply this rule to every package from this operator',
              ),
              onTap: () =>
                  Navigator.pop(context, const PricingPackageSelection.all()),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _load,
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : results.isEmpty
                  ? const Center(
                      child: Text('No matching packages were found.'),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        final details = [
                          if (item.destination.isNotEmpty) item.destination,
                          if (item.dataLabel.isNotEmpty) item.dataLabel,
                          if (item.validityLabel.isNotEmpty) item.validityLabel,
                        ].join(' · ');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (details.isNotEmpty) Text(details),
                              Text(
                                item.id,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (item.provider.toLowerCase() == 'manual')
                                const Text(
                                  'Manual Fulfillment',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                            ],
                          ),
                          trailing: Text(
                            item.price <= 0
                                ? 'Contact Admin'
                                : item.formattedPrice,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          onTap: () => Navigator.pop(
                            context,
                            PricingPackageSelection.package(item),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
