import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../packages/package_catalog.dart';
import '../partners/dealer_network_data.dart';
import 'pricing_repository.dart';
import 'pricing_rule.dart';

class DealerPricingScreen extends StatefulWidget {
  const DealerPricingScreen({super.key});

  @override
  State<DealerPricingScreen> createState() => _DealerPricingScreenState();
}

class _DealerPricingScreenState extends State<DealerPricingScreen> {
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
      final data = await _repository.fetchWorkspace();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Pricing rules could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRule({PricingRule? rule}) async {
    final data = _data;
    if (data == null || data.dealers.isEmpty) return;
    final providers = _providers(data.packages);
    if (providers.isEmpty) return;

    var dealerId = rule?.dealerId ?? data.dealers.first.id;
    var provider = rule?.provider.isNotEmpty == true ? rule!.provider : providers.first;
    var packageId = rule?.packageId ?? '';
    final markup = TextEditingController(
      text: rule?.markupPercentage.toStringAsFixed(2) ?? '0',
    );
    var submitting = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final packages = data.packages
              .where((item) => item.provider == provider)
              .toList();
          if (packageId.isNotEmpty &&
              !packages.any((item) => item.id == packageId)) {
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
                    rule == null ? 'New dealer price rule' : 'Edit price rule',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  const Text(
                    'Set dealer pricing by provider or package without changing the premium mobile shell.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: B2BSpacing.lg),
                  DropdownButtonFormField<int>(
                    initialValue: dealerId,
                    decoration: const InputDecoration(labelText: 'Dealer'),
                    items: data.dealers
                        .map(
                          (dealer) => DropdownMenuItem(
                            value: dealer.id,
                            child: Text(dealer.name),
                          ),
                        )
                        .toList(),
                    onChanged: submitting
                        ? null
                        : (value) => setSheetState(
                              () => dealerId = value ?? dealerId,
                            ),
                  ),
                  const SizedBox(height: B2BSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: provider,
                    decoration: const InputDecoration(labelText: 'Provider'),
                    items: providers
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_providerLabel(item)),
                          ),
                        )
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
                    initialValue: packageId,
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
                        : (value) => setSheetState(
                              () => packageId = value ?? '',
                            ),
                  ),
                  const SizedBox(height: B2BSpacing.md),
                  TextField(
                    controller: markup,
                    enabled: !submitting,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Markup %',
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final value = double.tryParse(markup.text.trim());
                              if (value == null) {
                                setSheetState(
                                  () => error =
                                      'Enter a valid markup percentage.',
                                );
                                return;
                              }
                              setSheetState(() {
                                submitting = true;
                                error = null;
                              });
                              try {
                                if (rule == null) {
                                  await _repository.createRule(
                                    dealerId: dealerId,
                                    provider: provider,
                                    packageId: packageId,
                                    markup: value,
                                  );
                                } else {
                                  await _repository.updateRule(
                                    rule,
                                    markup: value,
                                  );
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
                      child: Text(
                        submitting
                            ? 'Saving...'
                            : rule == null
                                ? 'Save rule'
                                : 'Update rule',
                      ),
                    ),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final rules = data?.rules.where((rule) => rule.dealerId != null).toList() ??
        const <PricingRule>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Dealer Pricing'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: data == null || data.dealers.isEmpty
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
            Text(
              'Commercial pricing',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Control dealer markup by provider and package scope.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading pricing rules...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Rules',
                      value: '${rules.length}',
                      icon: Icons.rule_rounded,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: _Stat(
                      label: 'Dealers',
                      value: '${data.dealers.length}',
                      icon: Icons.storefront_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (rules.isEmpty)
                const ContentEmptyState(
                  icon: Icons.percent_rounded,
                  title: 'No dealer pricing rules',
                  message: 'Create a rule to set dealer customer markup.',
                )
              else
                for (final rule in rules) ...[
                  _RuleCard(
                    rule: rule,
                    dealer: _dealer(data.dealers, rule.dealerId),
                    package: _package(data.packages, rule.packageId),
                    onEdit: () => _openRule(rule: rule),
                    onDelete: () => _delete(rule),
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

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => B2BSurface(
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: B2BSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.dealer,
    required this.package,
    required this.onEdit,
    required this.onDelete,
  });

  final PricingRule rule;
  final DealerSummary? dealer;
  final MobilePackage? package;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => B2BSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dealer?.name ?? 'Dealer #${rule.dealerId}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_providerLabel(rule.provider)} · ${package?.name ?? (rule.packageId.isEmpty ? 'All packages' : rule.packageId)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: B2BSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Mini(
                    label: 'Markup',
                    value: '${rule.markupPercentage.toStringAsFixed(2)}%',
                  ),
                ),
                Expanded(
                  child: _Mini(label: 'Priority', value: '${rule.priority}'),
                ),
                Expanded(
                  child: _Mini(
                    label: 'Status',
                    value: rule.isActive ? 'Active' : 'Inactive',
                    end: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, this.end = false});

  final String label;
  final String value;
  final bool end;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      );
}

List<String> _providers(List<MobilePackage> packages) {
  final values = packages
      .map((item) => item.provider)
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return values;
}

DealerSummary? _dealer(List<DealerSummary> items, int? id) {
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}

MobilePackage? _package(List<MobilePackage> items, String id) {
  if (id.isEmpty) return null;
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
