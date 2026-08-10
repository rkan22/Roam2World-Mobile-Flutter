import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'package_catalog.dart';
import 'packages_repository.dart';

class CatalogControlsScreen extends StatefulWidget {
  const CatalogControlsScreen({super.key});
  @override State<CatalogControlsScreen> createState() => _CatalogControlsScreenState();
}

class _CatalogControlsScreenState extends State<CatalogControlsScreen> {
  final _repository = PackagesRepository();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<MobilePackage> _packages = const [];
  String _provider = 'all';

  @override void initState() { super.initState(); _load(); _search.addListener(() => setState(() {})); }
  @override void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = _packages.isEmpty; _error = null; });
    try {
      final result = await _repository.fetchPackages(limit: 200, forceRefresh: true);
      if (mounted) setState(() => _packages = result.packages);
    } on ApiException catch (e) { if (mounted) setState(() => _error = e.message); }
    catch (_) { if (mounted) setState(() => _error = 'Catalog controls could not load packages.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<MobilePackage> get _visible {
    final q = _search.text.trim().toLowerCase();
    return _packages.where((p) {
      final provider = p.displayProvider;
      return (_provider == 'all' || provider == _provider) &&
          (q.isEmpty || [p.name, p.id, p.destination, p.dataLabel, p.validityLabel, provider].any((v) => v.toLowerCase().contains(q)));
    }).toList();
  }

  @override Widget build(BuildContext context) {
    final providers = _packages.map((p) => p.displayProvider).toSet().toList()..sort();
    final featured = _packages.where((p) => p.isFeatured).length;
    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)), title: const Text('Catalog Controls'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
      body: RefreshIndicator(onRefresh: _load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.xs, B2BSpacing.lg, B2BSpacing.xxl), children: [
        Text('Catalog management', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: B2BSpacing.xs),
        const Text('Review provider plans and server-backed featured state.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: B2BSpacing.md),
        B2BSurface(showShadow: false, backgroundColor: AppColors.warning.withValues(alpha: .08), borderColor: AppColors.warning.withValues(alpha: .3), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline_rounded, color: AppColors.warning), SizedBox(width: B2BSpacing.sm), Expanded(child: Text('Visibility / recommended controls are read-only in mobile until the backend catalog-controls endpoint is confirmed. Web currently keeps these rules locally when the endpoint is unavailable.', style: TextStyle(fontWeight: FontWeight.w700)))])),
        const SizedBox(height: B2BSpacing.lg),
        if (_loading) const ContentLoadingState(label: 'Loading catalog controls...')
        else if (_error != null && _packages.isEmpty) ContentErrorState(message: _error!, onRetry: _load)
        else ...[
          Row(children: [Expanded(child: _Stat(label: 'Plans', value: '${_packages.length}', icon: Icons.inventory_2_outlined)), const SizedBox(width: B2BSpacing.sm), Expanded(child: _Stat(label: 'Featured', value: '$featured', icon: Icons.star_outline_rounded))]),
          const SizedBox(height: B2BSpacing.lg),
          TextField(controller: _search, decoration: const InputDecoration(hintText: 'Search plan, provider, destination...', prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: B2BSpacing.sm),
          DropdownButtonFormField<String>(value: _provider, decoration: const InputDecoration(labelText: 'Provider'), items: [const DropdownMenuItem(value: 'all', child: Text('All providers')), ...providers.map((p) => DropdownMenuItem(value: p, child: Text(p)))], onChanged: (value) => setState(() => _provider = value ?? 'all')),
          const SizedBox(height: B2BSpacing.lg),
          if (_visible.isEmpty) const ContentEmptyState(icon: Icons.inventory_2_outlined, title: 'No plans found', message: 'Try another provider or search term.')
          else for (final package in _visible) ...[
            B2BSurface(child: Row(children: [
              Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(B2BRadius.md)), child: Icon(package.productKind == 'SIM Card' ? Icons.sim_card_rounded : Icons.qr_code_2_rounded, color: AppColors.primary)),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(package.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text('${package.displayProvider} · ${package.destination}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)), const SizedBox(height: 2), Text('${package.dataLabel} · ${package.validityLabel}', style: Theme.of(context).textTheme.bodySmall)])),
              if (package.isFeatured) const Icon(Icons.star_rounded, color: AppColors.warning),
            ])),
            const SizedBox(height: B2BSpacing.sm),
          ],
        ],
      ])),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon}); final String label; final String value; final IconData icon;
  @override Widget build(BuildContext context) => B2BSurface(child: Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: B2BSpacing.sm), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.textSecondary)), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))]) ]));
}
