import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../packages/package_catalog.dart';
import '../packages/packages_repository.dart';
import 'pricing_package_picker.dart';

class CentralPricingRulesScreen extends StatefulWidget {
  const CentralPricingRulesScreen({super.key});

  @override
  State<CentralPricingRulesScreen> createState() =>
      _CentralPricingRulesScreenState();
}

class _CentralPricingRulesScreenState extends State<CentralPricingRulesScreen> {
  final _repository = _PricingRulesRepository();
  final _packagesRepository = PackagesRepository();
  final _packageController = TextEditingController();
  final Map<String, String> _packageNames = {};
  final _markupController = TextEditingController(text: '0');
  final _minMarkupController = TextEditingController();
  final _maxMarkupController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');
  final _resellerController = TextEditingController();
  final _dealerController = TextEditingController();
  final _previewPriceController = TextEditingController(text: '25');

  static const _providers = <String, String>{
    'airhub': 'Vodafone',
    'worldmove': 'Orange Europe',
    'flexnet': 'Orange Big Data',
    'tgt': 'Orange Balkans',
    'manual': 'Manual Fulfillment',
  };

  static const _roles = <String, String>{
    'admin': 'Admin layer',
    'whatsapp_customer': 'WhatsApp customer',
    'reseller': 'Reseller layer',
    'dealer': 'Dealer layer',
  };

  List<_PricingRule> _rules = const [];
  String _provider = 'airhub';
  String _targetRole = 'admin';
  bool _active = true;
  bool _loading = true;
  bool _saving = false;
  bool _previewing = false;
  bool _manualPackageId = false;
  String? _selectedPackageName;
  String? _error;
  _PricePreview? _preview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _packageController.dispose();
    _markupController.dispose();
    _minMarkupController.dispose();
    _maxMarkupController.dispose();
    _priorityController.dispose();
    _resellerController.dispose();
    _dealerController.dispose();
    _previewPriceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rules = await _repository.fetchRules();
      if (!mounted) return;
      setState(
        () => _rules = rules
            .where((rule) => rule.provider != 'esimcard')
            .toList(),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Pricing rules could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _packageKey(String provider, String packageId) =>
      '${provider.toLowerCase()}|${packageId.toLowerCase()}';

  String? _packageNameForRule(_PricingRule rule) {
    if (rule.packageId.isEmpty) return null;
    return _packageNames[_packageKey(rule.provider, rule.packageId)];
  }

  void _rememberPackages(List<MobilePackage> packages) {
    if (!mounted) return;
    setState(() {
      for (final package in packages) {
        _packageNames[_packageKey(package.provider, package.id)] = package.name;
      }
    });
  }

  Future<void> _selectPackage() async {
    final selection = await showPricingPackagePicker(
      context: context,
      provider: _provider,
      repository: _packagesRepository,
      onCatalogLoaded: _rememberPackages,
    );
    if (!mounted || selection == null) return;

    if (selection.allPackages) {
      setState(() {
        _packageController.clear();
        _selectedPackageName = 'All packages';
        _manualPackageId = false;
        _preview = null;
      });
      return;
    }

    final package = selection.package;
    if (package == null) return;

    setState(() {
      _packageController.text = package.id;
      _selectedPackageName = package.name;
      _manualPackageId = false;
      _previewPriceController.text = package.price.toStringAsFixed(2);
      _packageNames[_packageKey(package.provider, package.id)] = package.name;
      _preview = null;
    });
  }

  void _changeProvider(String value) {
    setState(() {
      _provider = value;
      _packageController.clear();
      _selectedPackageName = null;
      _manualPackageId = false;
      _preview = null;
    });
  }

  Future<void> _save() async {
    final markup = double.tryParse(_markupController.text.trim());
    final priority = int.tryParse(_priorityController.text.trim());
    if (markup == null || markup < 0) {
      _showMessage('Enter a valid markup percentage.');
      return;
    }
    if (priority == null) {
      _showMessage('Enter a valid priority.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.createRule(
        provider: _provider,
        packageId: _packageController.text.trim(),
        targetRole: _targetRole,
        resellerId: int.tryParse(_resellerController.text.trim()),
        dealerId: int.tryParse(_dealerController.text.trim()),
        markup: markup,
        minMarkup: _optionalDouble(_minMarkupController.text),
        maxMarkup: _optionalDouble(_maxMarkupController.text),
        priority: priority,
        isActive: _active,
      );
      if (!mounted) return;
      _packageController.clear();
      _selectedPackageName = null;
      _manualPackageId = false;
      _markupController.text = '0';
      _minMarkupController.clear();
      _maxMarkupController.clear();
      _priorityController.text = '0';
      _resellerController.clear();
      _dealerController.clear();
      _preview = null;
      _showMessage('Central pricing rule saved.');
      await _load();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Pricing rule could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(_PricingRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete pricing rule?'),
        content: Text(
          '${_providers[rule.provider] ?? rule.provider} · ${rule.packageId.isEmpty ? 'All packages' : rule.packageId}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteRule(rule.id);
      if (!mounted) return;
      setState(
        () => _rules = _rules.where((item) => item.id != rule.id).toList(),
      );
      _showMessage('Pricing rule deleted.');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _calculatePreview() async {
    final providerPrice = double.tryParse(_previewPriceController.text.trim());
    if (providerPrice == null || providerPrice < 0) {
      _showMessage('Enter a valid provider cost.');
      return;
    }

    setState(() => _previewing = true);
    try {
      final preview = await _repository.preview(
        provider: _provider,
        packageId: _packageController.text.trim(),
        providerPrice: providerPrice,
      );
      if (mounted) setState(() => _preview = preview);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Price preview failed.');
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  double? _optionalDouble(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _rules.where((rule) => rule.isActive).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central Pricing Rules'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.sm,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            Text(
              'Control commercial pricing by operator and account scope.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: B2BSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Rules',
                    value: '${_rules.length}',
                    icon: Icons.rule_rounded,
                  ),
                ),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(
                  child: _MetricCard(
                    label: 'Active',
                    value: '$activeCount',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: B2BSpacing.lg),
            Text('New rule', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: B2BSpacing.sm),
            B2BSurface(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _provider,
                    decoration: const InputDecoration(labelText: 'Operator'),
                    items: _providers.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null && value != _provider) {
                              _changeProvider(value);
                            }
                          },
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                  InkWell(
                    onTap: _saving ? null : _selectPackage,
                    borderRadius: BorderRadius.circular(B2BRadius.md),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Package',
                        helperText: 'Search by package name, ID or destination',
                        suffixIcon: Icon(Icons.search_rounded),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPackageName ?? 'All packages',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (_packageController.text.trim().isNotEmpty)
                            Text(
                              _packageController.text.trim(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _manualPackageId = !_manualPackageId;
                              if (!_manualPackageId) {
                                _packageController.clear();
                                _selectedPackageName = null;
                              }
                              _preview = null;
                            }),
                      icon: Icon(
                        _manualPackageId
                            ? Icons.expand_less_rounded
                            : Icons.tune_rounded,
                      ),
                      label: Text(
                        _manualPackageId
                            ? 'Hide manual Product ID'
                            : 'Advanced: enter Product ID manually',
                      ),
                    ),
                  ),
                  if (_manualPackageId) ...[
                    TextField(
                      controller: _packageController,
                      enabled: !_saving,
                      onChanged: (_) => setState(() {
                        _selectedPackageName = null;
                        _preview = null;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Product ID',
                        hintText: 'Leave empty to apply to all packages',
                      ),
                    ),
                    const SizedBox(height: B2BSpacing.sm),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: _targetRole,
                    decoration: const InputDecoration(
                      labelText: 'Pricing layer',
                    ),
                    items: _roles.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(
                            () => _targetRole = value ?? _targetRole,
                          ),
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _markupController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Markup %',
                          ),
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _priorityController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minMarkupController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Min markup %',
                          ),
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _maxMarkupController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Max markup %',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _resellerController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Reseller ID (optional)',
                          ),
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _dealerController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Dealer ID (optional)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active rule'),
                    value: _active,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _active = value),
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save rule'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.lg),
            Text(
              'Price preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: B2BSpacing.sm),
            B2BSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _previewPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Provider cost',
                      prefixText: 'USD ',
                    ),
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _previewing ? null : _calculatePreview,
                      icon: _previewing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calculate_outlined),
                      label: const Text('Calculate backend price'),
                    ),
                  ),
                  if (_preview != null) ...[
                    const SizedBox(height: B2BSpacing.md),
                    Wrap(
                      spacing: B2BSpacing.sm,
                      runSpacing: B2BSpacing.sm,
                      children: [
                        _PreviewChip(
                          label: 'Admin',
                          value: _preview!.afterAdmin,
                        ),
                        _PreviewChip(
                          label: 'Reseller',
                          value: _preview!.afterReseller,
                        ),
                        _PreviewChip(
                          label: 'Final',
                          value: _preview!.finalCustomerPrice,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.lg),
            Text(
              'Effective rules',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: B2BSpacing.sm),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(B2BSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              B2BSurface(
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: B2BSpacing.sm),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_rules.isEmpty)
              const B2BSurface(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: B2BSpacing.lg),
                  child: Center(child: Text('No central pricing rules.')),
                ),
              )
            else
              ..._rules.map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: B2BSpacing.sm),
                  child: _RuleCard(
                    rule: rule,
                    operatorLabel: _providers[rule.provider] ?? rule.provider,
                    packageName: _packageNameForRule(rule),
                    onDelete: () => _delete(rule),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: B2BSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
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
    required this.operatorLabel,
    required this.packageName,
    required this.onDelete,
  });

  final _PricingRule rule;
  final String operatorLabel;
  final String? packageName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => B2BSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                operatorLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: rule.isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(B2BRadius.pill),
              ),
              child: Text(rule.isActive ? 'Active' : 'Inactive'),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete rule',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: B2BSpacing.xs),
        if (rule.packageId.isEmpty)
          const Text(
            'All packages',
            style: TextStyle(fontWeight: FontWeight.w800),
          )
        else ...[
          Text(
            packageName ?? rule.packageId,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (packageName != null)
            Text(rule.packageId, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: B2BSpacing.sm),
        Wrap(
          spacing: B2BSpacing.sm,
          runSpacing: B2BSpacing.xs,
          children: [
            _MetaChip('Layer', rule.targetRole),
            _MetaChip('Markup', '${rule.markup.toStringAsFixed(2)}%'),
            _MetaChip('Priority', '${rule.priority}'),
            if (rule.resellerId != null)
              _MetaChip('Reseller', '${rule.resellerId}'),
            if (rule.dealerId != null) _MetaChip('Dealer', '${rule.dealerId}'),
          ],
        ),
      ],
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(B2BRadius.pill),
    ),
    child: Text('$label: $value', style: Theme.of(context).textTheme.bodySmall),
  );
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(B2BRadius.md),
    ),
    child: Text(
      '$label: ${value ?? 'Hidden'}',
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}

class _PricingRule {
  const _PricingRule({
    required this.id,
    required this.provider,
    required this.packageId,
    required this.targetRole,
    required this.markup,
    required this.priority,
    required this.isActive,
    this.resellerId,
    this.dealerId,
  });

  final int id;
  final String provider;
  final String packageId;
  final String targetRole;
  final double markup;
  final int priority;
  final bool isActive;
  final int? resellerId;
  final int? dealerId;

  factory _PricingRule.fromJson(Map<String, dynamic> json) => _PricingRule(
    id: int.tryParse('${json['id'] ?? 0}') ?? 0,
    provider: '${json['provider'] ?? ''}',
    packageId: '${json['package_id'] ?? ''}',
    targetRole: '${json['target_role'] ?? ''}',
    markup: double.tryParse('${json['markup_percentage'] ?? 0}') ?? 0,
    priority: int.tryParse('${json['priority'] ?? 0}') ?? 0,
    isActive: json['is_active'] == true,
    resellerId: int.tryParse('${json['reseller'] ?? ''}'),
    dealerId: int.tryParse('${json['dealer'] ?? ''}'),
  );
}

class _PricePreview {
  const _PricePreview({
    this.afterAdmin,
    this.afterReseller,
    this.finalCustomerPrice,
  });
  final String? afterAdmin;
  final String? afterReseller;
  final String? finalCustomerPrice;

  factory _PricePreview.fromJson(Map<String, dynamic> json) => _PricePreview(
    afterAdmin: json['after_admin']?.toString(),
    afterReseller: json['after_reseller']?.toString(),
    finalCustomerPrice: json['final_customer_price']?.toString(),
  );
}

class _PricingRulesRepository {
  _PricingRulesRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  Future<List<_PricingRule>> fetchRules() {
    return _apiClient.get<List<_PricingRule>>(
      ApiEndpoints.pricingRules,
      parser: (response) {
        final root = response is Map
            ? Map<String, dynamic>.from(response)
            : <String, dynamic>{};
        final dynamic raw = response is List
            ? response
            : root['results'] ?? root['data'] ?? const [];
        final list = raw is Map
            ? raw['results'] ?? raw['data'] ?? const []
            : raw;
        if (list is! List) return const [];
        return list
            .whereType<Map>()
            .map(
              (item) => _PricingRule.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      },
    );
  }

  Future<void> createRule({
    required String provider,
    required String packageId,
    required String targetRole,
    required int? resellerId,
    required int? dealerId,
    required double markup,
    required double? minMarkup,
    required double? maxMarkup,
    required int priority,
    required bool isActive,
  }) {
    return _apiClient.post<void>(
      ApiEndpoints.pricingRules,
      data: {
        'provider': provider,
        'package_id': packageId.isEmpty ? null : packageId,
        'target_role': targetRole,
        'reseller': resellerId,
        'dealer': dealerId,
        'markup_percentage': markup,
        'min_markup_percentage': minMarkup,
        'max_markup_percentage': maxMarkup,
        'priority': priority,
        'is_active': isActive,
      },
      parser: (_) {},
    );
  }

  Future<void> deleteRule(int id) =>
      _apiClient.delete(ApiEndpoints.pricingRuleDetail(id));

  Future<_PricePreview> preview({
    required String provider,
    required String packageId,
    required double providerPrice,
  }) {
    return _apiClient.post<_PricePreview>(
      ApiEndpoints.pricingPreview,
      data: {
        'provider': provider,
        'package_id': packageId.isEmpty ? null : packageId,
        'provider_price': providerPrice,
        'currency': 'USD',
      },
      parser: (response) {
        final root = Map<String, dynamic>.from(response as Map);
        final data = root['data'] is Map
            ? Map<String, dynamic>.from(root['data'] as Map)
            : root;
        return _PricePreview.fromJson(data);
      },
    );
  }
}
