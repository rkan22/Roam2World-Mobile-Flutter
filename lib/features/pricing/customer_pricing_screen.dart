import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../packages/package_catalog.dart';
import 'pricing_repository.dart';
import 'pricing_rule.dart';

class CustomerPricingScreen extends StatefulWidget {
  const CustomerPricingScreen({super.key});

  @override
  State<CustomerPricingScreen> createState() => _CustomerPricingScreenState();
}

class _CustomerPricingScreenState extends State<CustomerPricingScreen> {
  final _repository = PricingRepository();
  PricingWorkspaceData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await _repository.fetchDealerCustomerWorkspace();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Customer pricing could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRule({PricingRule? rule}) async {
    final data = _data;
    if (data == null) return;
    final providers = _providers(data.packages);
    if (providers.isEmpty) return;

    var provider = rule?.provider.isNotEmpty == true ? rule!.provider : providers.first;
    var packageId = rule?.packageId ?? '';
    final markup = TextEditingController(text: rule?.markupPercentage.toStringAsFixed(2) ?? '0');
    String? error;
    var submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final packages = data.packages.where((item) => item.provider == provider).toList();
          if (packageId.isNotEmpty && !packages.any((item) => item.id == packageId)) {
            packageId = '';
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(
              B2BSpacing.lg,
              0,
              B2BSpacing.lg,
              MediaQuery.viewInsetsOf(context).bottom + B2BSpacing.xl,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule == null ? 'New customer price rule' : 'Edit customer price rule',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  const Text(
                    'Set your customer-facing markup by operator or individual package.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: B2BSpacing.lg),
                  DropdownButtonFormField<String>(
                    value: provider,
                    decoration: const InputDecoration(labelText: 'Provider'),
                    items: providers
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(_providerLabel(item)),
                            ))
                        .toList(),
                    onChanged: submitting
                        ? null
                        : (value) => setSheetState(() {
                              provider = value ?? provider;
                              packageId = '';
                            }),
                  ),
                  const SizedBox(height: B2BSpacing.md),
                  DropdownButtonFormField<String>(
                    value: packageId,
                    decoration: const InputDecoration(labelText: 'Package scope'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All packages for this provider'),
                      ),
                      ...packages.map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} · ${item.dataLabel} · ${item.validityLabel}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: submitting
                        ? null
                        : (value) => setSheetState(() => packageId = value ?? ''),
                  ),
                  const SizedBox(height: B2BSpacing.md),
                  TextField(
                    controller: markup,
                    enabled: !submitting,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Customer markup %',
                      prefixIcon: Icon(Icons.percent_rounded),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: B2BSpacing.sm),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: B2BSpacing.lg),
                  ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            final value = double.tryParse(markup.text.trim());
                            if (value == null) {
                              setSheetState(() => error = 'Enter a valid markup percentage.');
                              return;
                            }
                            setSheetState(() {
                              submitting = true;
                              error = null;
                            });
                            try {
                              if (rule == null) {
                                await _repository.createDealerCustomerRule(
                                  provider: provider,
                                  packageId: packageId,
                                  markup: value,
                                );
                              } else {
                                await _repository.updateRule(rule, markup: value);
                              }
                              if (!mounted || !sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              await _load();
                            } on ApiException catch (apiError) {
                              setSheetState(() => error = apiError.message);
                            } finally {
                              if (sheetContext.mounted) {
                                setSheetState(() => submitting = false);
                              }
                            }
                          },
                    child: Text(submitting ? 'Saving...' : 'Save pricing rule'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    markup.dispose();
  }

  Future<void> _delete(PricingRule rule) async {
    try {
      await _repository.deleteRule(rule.id);
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final rules = data?.rules
            .where((rule) => rule.targetRole.toLowerCase() == 'dealer' && rule.dealerId == null)
            .toList() ??
        const <PricingRule>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Customer Pricing'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openRule(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New rule'),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.xs,
            B2BSpacing.lg,
            110,
          ),
          children: [
            Text('Dealer customer pricing', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Control your retail markup without changing reseller or provider cost.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading customer pricing...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (rules.isEmpty)
              const ContentEmptyState(
                icon: Icons.percent_rounded,
                title: 'No customer price rules',
                message: 'Create a markup rule for your customer-facing prices.',
              )
            else
              for (final rule in rules) ...[
                B2BSurface(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _providerLabel(rule.provider),
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              rule.packageId.isEmpty
                                  ? 'All packages'
                                  : (_package(data!.packages, rule.packageId)?.name ?? rule.packageId),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: B2BSpacing.sm),
                            Text(
                              '${rule.markupPercentage.toStringAsFixed(2)}% markup · priority ${rule.priority}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) =>
                            value == 'edit' ? _openRule(rule: rule) : _delete(rule),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: B2BSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

List<String> _providers(List<MobilePackage> packages) {
  final values = packages.map((item) => item.provider).where((item) => item.isNotEmpty).toSet().toList()
    ..sort();
  return values;
}

MobilePackage? _package(List<MobilePackage> items, String id) {
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}

String _providerLabel(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('airhub')) return 'Vodafone';
  if (normalized.contains('worldmove')) return 'Orange Europe';
  if (normalized.contains('flexnet')) return 'Orange Big Data';
  if (normalized.contains('tgt')) return 'Orange Balkans';
  return value.isEmpty ? 'Provider' : value;
}
