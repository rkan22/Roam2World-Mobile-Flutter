import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'provider_operations_repository.dart';

class ProviderOperationsScreen extends StatefulWidget {
  const ProviderOperationsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ProviderOperationsScreen> createState() =>
      _ProviderOperationsScreenState();
}

class _ProviderOperationsScreenState extends State<ProviderOperationsScreen>
    with SingleTickerProviderStateMixin {
  final _repository = ProviderOperationsRepository();
  final _usageController = TextEditingController();
  final _esimIdController = TextEditingController();
  final _worldmoveSimController = TextEditingController();
  final _worldmoveProductController = TextEditingController();
  late final TabController _tabController;

  String _usageProvider = 'tgt';
  String _renewProvider = 'tgt';
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _usageResult;
  Map<String, dynamic>? _operationResult;
  List<Map<String, dynamic>> _renewalOptions = const [];
  Map<String, dynamic>? _selectedOption;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usageController.dispose();
    _esimIdController.dispose();
    _worldmoveSimController.dispose();
    _worldmoveProductController.dispose();
    super.dispose();
  }

  Future<void> _runUsage() async {
    if (_usageController.text.trim().isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _usageResult = null;
    });
    try {
      final result = await _repository.checkUsage(
        provider: _usageProvider,
        lookup: _usageController.text,
      );
      if (mounted) setState(() => _usageResult = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRenewalOptions() async {
    final esimId = int.tryParse(_esimIdController.text.trim());
    if (esimId == null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _renewalOptions = const [];
      _selectedOption = null;
    });
    try {
      final options = await _repository.renewalOptions(
        provider: _renewProvider,
        esimId: esimId,
      );
      if (mounted) {
        setState(() {
          _renewalOptions = options;
          _selectedOption = options.isEmpty ? null : options.first;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitRenewal() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _operationResult = null;
    });
    try {
      Map<String, dynamic> result;
      if (_renewProvider == 'worldmove') {
        final sim = _worldmoveSimController.text.trim();
        final product = _worldmoveProductController.text.trim();
        if (!RegExp(r'^\d{20}$').hasMatch(sim)) {
          throw const FormatException(
            'Worldmove requires a 20-digit SIM number.',
          );
        }
        if (product.isEmpty) {
          throw const FormatException('Worldmove product ID is required.');
        }
        result = await _repository.topupWorldmove(
          simNumber: sim,
          productId: product,
        );
      } else {
        final esimId = int.tryParse(_esimIdController.text.trim());
        if (esimId == null) throw const FormatException('eSIM ID is required.');
        final option = _selectedOption;
        final rawData =
            option?['data_gb'] ?? option?['dataGb'] ?? option?['data_amount'];
        final dataGb = num.tryParse('$rawData');
        if (dataGb == null) {
          throw const FormatException('Select a live renewal option first.');
        }
        result = _renewProvider == 'tgt'
            ? await _repository.renewTgt(esimId: esimId, dataGb: dataGb)
            : await _repository.renewVodafone(esimId: esimId, dataGb: dataGb);
      }
      if (mounted) setState(() => _operationResult = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException ? error.message : '$error',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider tools'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'GB Query'),
            Tab(text: 'Renew / Top-up'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_usageTab(), _renewTab()],
      ),
    );
  }

  Widget _usageTab() => ListView(
    padding: const EdgeInsets.all(B2BSpacing.lg),
    children: [
      Text(
        'GB Query / Usage Check',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      const Text(
        'Query live provider usage using the identifiers supported by each provider.',
      ),
      const SizedBox(height: 18),
      DropdownButtonFormField<String>(
        initialValue: _usageProvider,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Provider'),
        items: const [
          DropdownMenuItem(
            value: 'tgt',
            child: Text(
              'Orange Balkans',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DropdownMenuItem(
            value: 'airhub',
            child: Text(
              'Vodafone',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DropdownMenuItem(
            value: 'worldmove',
            child: Text(
              'Orange Europe',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        onChanged: _loading
            ? null
            : (value) => setState(() {
                _usageProvider = value ?? 'tgt';
                _usageResult = null;
              }),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _usageController,
        enabled: !_loading,
        decoration: InputDecoration(
          labelText: _usageProvider == 'worldmove'
              ? 'SIM card number'
              : _usageProvider == 'airhub'
              ? 'ICCID or provider order ID'
              : '8997 ICCID or order number',
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: _loading ? null : _runUsage,
        icon: const Icon(Icons.data_usage_rounded),
        label: Text(_loading ? 'Checking…' : 'Check usage'),
      ),
      if (_usageProvider == 'tgt') ...[
        const SizedBox(height: 10),
        const Text(
          'TGT rule: 8997 ICCIDs support GB check; 8933 ICCIDs do not.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
      if (_error != null) _message(_error!, false),
      if (_usageResult != null) _resultCard(_usageResult!),
    ],
  );

  Widget _renewTab() => ListView(
    padding: const EdgeInsets.all(B2BSpacing.lg),
    children: [
      Text('Renew / Top-up', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      const Text(
        'Uses live backend renewal options and provider checkout endpoints. No demo prices or package options are used.',
      ),
      const SizedBox(height: 18),
      DropdownButtonFormField<String>(
        initialValue: _renewProvider,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Provider'),
        items: const [
          DropdownMenuItem(
            value: 'tgt',
            child: Text(
              'Orange Balkans',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DropdownMenuItem(
            value: 'airhub',
            child: Text(
              'Vodafone',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DropdownMenuItem(
            value: 'worldmove',
            child: Text(
              'Orange Europe',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        onChanged: _loading
            ? null
            : (value) => setState(() {
                _renewProvider = value ?? 'tgt';
                _renewalOptions = const [];
                _selectedOption = null;
                _operationResult = null;
              }),
      ),
      const SizedBox(height: 12),
      if (_renewProvider == 'worldmove') ...[
        TextField(
          controller: _worldmoveSimController,
          keyboardType: TextInputType.number,
          maxLength: 20,
          decoration: const InputDecoration(
            labelText: '20-digit SIM card number',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _worldmoveProductController,
          decoration: const InputDecoration(
            labelText: 'Worldmove product ID',
            helperText: 'Use the exact product ID from the live catalog.',
          ),
        ),
      ] else ...[
        TextField(
          controller: _esimIdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'eSIM ID'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _loading ? null : _loadRenewalOptions,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Load live renewal options'),
        ),
        if (_renewalOptions.isNotEmpty) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _selectedOption,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Renewal option'),
            items: _renewalOptions
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      _optionLabel(option),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _loading
                ? null
                : (value) => setState(() => _selectedOption = value),
          ),
        ],
      ],
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: _loading ? null : _submitRenewal,
        icon: const Icon(Icons.autorenew_rounded),
        label: Text(
          _loading
              ? 'Submitting…'
              : (_renewProvider == 'worldmove'
                    ? 'Submit top-up'
                    : 'Submit renewal'),
        ),
      ),
      if (_error != null) _message(_error!, false),
      if (_operationResult != null) _resultCard(_operationResult!),
    ],
  );

  Widget _resultCard(Map<String, dynamic> result) {
    final success = result['success'] != false;
    final usage = result['usage'] is Map
        ? Map<String, dynamic>.from(result['usage'])
        : result;
    final rows = <MapEntry<String, dynamic>>[];
    for (final key in const [
      'provider',
      'iccid',
      'status',
      'total_mb',
      'used_mb',
      'remaining_mb',
      'total',
      'used',
      'remaining',
      'start_date',
      'end_date',
      'message',
      'charged_amount',
      'product_code',
      'renewal_data_gb',
    ]) {
      final value = usage[key] ?? result[key];
      if (value != null && '$value'.trim().isNotEmpty) {
        rows.add(MapEntry(key, value));
      }
    }
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success ? AppColors.successSoft : AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(B2BRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            success ? 'Operation completed' : 'Operation failed',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text(
              result['error']?.toString() ?? 'No additional details returned.',
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${_pretty(row.key)}: ${row.value}'),
              ),
        ],
      ),
    );
  }

  Widget _message(String text, bool success) => Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: success ? AppColors.successSoft : AppColors.dangerSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: success ? AppColors.success : AppColors.danger,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static String _optionLabel(Map<String, dynamic> option) {
    final data = option['data_gb'] ?? option['dataGb'] ?? option['data_amount'];
    final days =
        option['validity_days'] ??
        option['validityDays'] ??
        option['validity_period'];
    final price = option['price'];
    return [
      if (data != null) '${data}GB',
      if (days != null) '$days Days',
      if (price != null) '$price',
    ].join(' · ');
  }

  static String _pretty(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}
