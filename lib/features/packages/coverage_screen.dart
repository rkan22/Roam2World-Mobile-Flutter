import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'package_catalog.dart';
import 'packages_repository.dart';

class CoverageScreen extends StatefulWidget {
  const CoverageScreen({super.key});

  @override
  State<CoverageScreen> createState() => _CoverageScreenState();
}

class _CoverageScreenState extends State<CoverageScreen> {
  final _repository = PackagesRepository();
  final _search = TextEditingController();
  List<MobilePackage> _packages = const [];
  bool _loading = true;
  String? _error;
  String? _provider;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _packages.isEmpty;
      _error = null;
    });
    try {
      final result = await _repository.fetchPackages(limit: 250, forceRefresh: true);
      if (mounted) setState(() => _packages = result.packages);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Coverage data could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MobilePackage> get _visible {
    final query = _search.text.trim().toLowerCase();
    return _packages.where((item) {
      final providerMatches = _provider == null || item.displayProvider == _provider;
      final text = [
        item.displayProvider,
        item.name,
        item.destination,
        item.dataLabel,
        item.validityLabel,
      ].join(' ').toLowerCase();
      return providerMatches && (query.isEmpty || text.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final providers = _packages.map((e) => e.displayProvider).where((e) => e.isNotEmpty).toSet().toList()..sort();
    final destinations = visible.map((e) => e.destination).where((e) => e.isNotEmpty).toSet();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Coverage'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.sm, B2BSpacing.lg, B2BSpacing.xxl),
          children: [
            Text('Coverage & availability', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text('Live coverage derived only from the mobile provider catalog.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading coverage...')
            else if (_error != null && _packages.isEmpty)
              ContentErrorState(message: _error!, onRetry: _load)
            else ...[
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Destinations', value: '${destinations.length}', icon: Icons.public_rounded)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Providers', value: '${providers.length}', icon: Icons.hub_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.sm),
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Plans', value: '${visible.length}', icon: Icons.layers_outlined)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Global plans', value: '${visible.where((e) => e.destination.toLowerCase().contains('global')).length}', icon: Icons.language_rounded)),
              ]),
              const SizedBox(height: B2BSpacing.lg),
              TextField(
                controller: _search,
                decoration: const InputDecoration(hintText: 'Search destination, provider, data or validity', prefixIcon: Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: B2BSpacing.sm),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: providers.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: B2BSpacing.xs),
                  itemBuilder: (context, index) {
                    final value = index == 0 ? null : providers[index - 1];
                    return ChoiceChip(
                      label: Text(value ?? 'All providers'),
                      selected: _provider == value,
                      onSelected: (_) => setState(() => _provider = value),
                    );
                  },
                ),
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (visible.isEmpty)
                const ContentEmptyState(icon: Icons.public_off_outlined, title: 'No coverage rows', message: 'Try another provider or search term.')
              else
                for (final item in visible) ...[
                  B2BSurface(
                    onTap: () => context.push('/packages/detail', extra: item),
                    child: Row(children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(B2BRadius.md)),
                        child: const Icon(Icons.public_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.destination, style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text('${item.displayProvider} · ${item.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: B2BSpacing.xs),
                        Text('${item.dataLabel} · ${item.validityLabel}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ])),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                ],
            ],
          ],
        ),
      ),
    );
  }
}
