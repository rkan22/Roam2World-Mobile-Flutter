import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'provider_lifecycle_repository.dart';

class ProviderToolsScreen extends StatefulWidget {
  const ProviderToolsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ProviderToolsScreen> createState() => _ProviderToolsScreenState();
}

class _ProviderToolsScreenState extends State<ProviderToolsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _repository = ProviderLifecycleRepository();
  final _lookup = TextEditingController();
  final _packageId = TextEditingController();
  String _provider = 'tgt';
  bool _loading = false;
  ProviderOperationResult? _result;

  static const _providers = <String, String>{
    'tgt': 'Orange Balkans',
    'airhub': 'Vodafone',
    'worldmove': 'Orange Europe',
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() => _result = null);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _lookup.dispose();
    _packageId.dispose();
    super.dispose();
  }

  Future<void> _submitUsage() async {
    final value = _lookup.text.trim();
    if (value.isEmpty) return _show('Enter an ICCID, eSIM ID, SIM number or order ID.');
    setState(() { _loading = true; _result = null; });
    try {
      final result = switch (_provider) {
        'tgt' => await _repository.checkTgtUsage(iccid: value),
        'airhub' => await _repository.checkAirhubUsage(iccid: value, orderId: value),
        _ => await _repository.checkWorldmoveUsage(iccid: value, orderId: value),
      };
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) _show('$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitRenewal() async {
    final lookup = _lookup.text.trim();
    final packageId = _packageId.text.trim();
    if (lookup.isEmpty || packageId.isEmpty) {
      return _show('Enter the SIM/eSIM identifier and package ID.');
    }
    if (_provider == 'worldmove' && !RegExp(r'^\d{20}$').hasMatch(lookup)) {
      return _show('Orange Europe requires a 20 digit SIM card number.');
    }
    setState(() { _loading = true; _result = null; });
    try {
      final result = switch (_provider) {
        'tgt' => await _repository.renewTgt(iccid: lookup, packageId: packageId),
        'airhub' => await _repository.renewVodafone(esimId: lookup, dataGb: packageId),
        _ => await _repository.topUpWorldmove(packageId: packageId, simNumber: lookup),
      };
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) _show('$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Provider tools'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'GB Query'),
            Tab(text: 'Renew / Top-up'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_usage(), _renewal()],
      ),
    );
  }

  Widget _providerSelector() => DropdownButtonFormField<String>(
        value: _provider,
        decoration: const InputDecoration(labelText: 'Provider'),
        items: _providers.entries
            .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
            .toList(growable: false),
        onChanged: _loading
            ? null
            : (value) => setState(() {
                  _provider = value ?? 'tgt';
                  _result = null;
                  _packageId.clear();
                }),
      );

  Widget _usage() => ListView(
        padding: const EdgeInsets.all(B2BSpacing.lg),
        children: [
          Text('GB Query / Usage Check', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: B2BSpacing.xs),
          const Text('Query live provider usage using the same provider flows as the web dashboard.'),
          const SizedBox(height: B2BSpacing.lg),
          _providerSelector(),
          const SizedBox(height: B2BSpacing.md),
          TextField(
            controller: _lookup,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: _provider == 'worldmove' ? 'SIM card number' : _provider == 'tgt' ? 'ICCID' : 'eSIM ID / order ID',
            ),
          ),
          const SizedBox(height: B2BSpacing.md),
          FilledButton.icon(
            onPressed: _loading ? null : _submitUsage,
            icon: const Icon(Icons.data_usage_rounded),
            label: Text(_loading ? 'Checking...' : 'Check usage'),
          ),
          if (_result != null) ...[
            const SizedBox(height: B2BSpacing.lg),
            _resultCard(_result!),
          ],
        ],
      );

  Widget _renewal() => ListView(
        padding: const EdgeInsets.all(B2BSpacing.lg),
        children: [
          Text('Renew / Top-up', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: B2BSpacing.xs),
          const Text('Submit real provider renewal or top-up requests. Unsupported providers are not shown.'),
          const SizedBox(height: B2BSpacing.lg),
          _providerSelector(),
          const SizedBox(height: B2BSpacing.md),
          TextField(
            controller: _lookup,
            enabled: !_loading,
            keyboardType: _provider == 'worldmove' ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              labelText: _provider == 'worldmove' ? '20 digit SIM card number' : 'ICCID / eSIM ID',
            ),
          ),
          const SizedBox(height: B2BSpacing.md),
          TextField(
            controller: _packageId,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: _provider == 'airhub' ? 'Renewal data GB (e.g. 200)' : 'Package ID',
              helperText: _provider == 'tgt'
                  ? 'Use a TGT renewal package ID.'
                  : _provider == 'worldmove'
                      ? 'Example: WM-EU-B-T10-30D'
                      : 'Example: 200, 400 or 500',
            ),
          ),
          const SizedBox(height: B2BSpacing.md),
          FilledButton.icon(
            onPressed: _loading ? null : _submitRenewal,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_loading ? 'Submitting...' : 'Submit'),
          ),
          if (_result != null) ...[
            const SizedBox(height: B2BSpacing.lg),
            _resultCard(_result!),
          ],
        ],
      );

  Widget _resultCard(ProviderOperationResult result) {
    final usage = result.data['usage'];
    final usageMap = usage is Map ? Map<String, dynamic>.from(usage) : <String, dynamic>{};
    final fields = <MapEntry<String, dynamic>>[
      if (usageMap.isNotEmpty) ...usageMap.entries,
      if (usageMap.isEmpty) ...result.data.entries.where((entry) => !['raw', 'order_info', 'activation_raw'].contains(entry.key)).take(8),
    ];
    return B2BSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(result.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: result.success ? AppColors.success : AppColors.danger),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Text(
                  result.message.isNotEmpty ? result.message : (result.success ? 'Operation completed' : 'Operation failed'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          for (final entry in fields) ...[
            const SizedBox(height: B2BSpacing.sm),
            Text('${entry.key.replaceAll('_', ' ')}: ${entry.value}'),
          ],
        ],
      ),
    );
  }
}
