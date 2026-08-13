import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'sim_agent_remote_repository.dart';

class RemoteSimAgentScreen extends StatefulWidget {
  const RemoteSimAgentScreen({super.key});

  @override
  State<RemoteSimAgentScreen> createState() => _RemoteSimAgentScreenState();
}

class _RemoteSimAgentScreenState extends State<RemoteSimAgentScreen> {
  final _agent = SimAgentRemoteRepository();
  final _api = ApiClient();
  List<Map<String, dynamic>> _devices = const [];
  List<Map<String, dynamic>> _jobs = const [];
  List<Map<String, dynamic>> _esims = const [];
  Map<String, dynamic> _credits = const {};
  String? _deviceId;
  String? _esimId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait<dynamic>([
        _agent.fetchDevices(),
        _agent.fetchJobs(),
        _agent.fetchCredits(),
        _api.get<List<Map<String, dynamic>>>(
          '/api/v1/mobile/esims/',
          queryParameters: const {'limit': 200},
          parser: _parseList,
        ),
      ]);
      if (!mounted) return;
      final devices = results[0] as List<Map<String, dynamic>>;
      setState(() {
        _devices = devices.where((d) => d['is_active'] != false).toList();
        _jobs = results[1] as List<Map<String, dynamic>>;
        _credits = results[2] as Map<String, dynamic>;
        _esims = results[3] as List<Map<String, dynamic>>;
        _deviceId ??= _devices.isEmpty ? null : _id(_devices.first);
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Remote SIM Agent data could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _queue() async {
    if (_deviceId == null || _esimId == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _agent.queueJob(deviceId: _deviceId!, esimId: _esimId!);
      if (!mounted) return;
      _esimId = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provisioning request queued. Local approval is still required.')),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Provisioning request could not be queued.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _number(_credits['available_balance']);
    final reserved = _number(_credits['reserved_balance']);
    final fee = _number(_credits['provisioning_fee'], fallback: 1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote SIM Agent'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(B2BSpacing.lg),
          children: [
            Text('Remote provisioning', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text('Queue a profile for a connected shop computer. Every physical-card write still requires local approval.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: B2BSpacing.lg),
            if (_error != null) B2BSurface(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700))),
            if (_error != null) const SizedBox(height: B2BSpacing.md),
            Row(children: [
              Expanded(child: _Metric(label: 'Agent Credits', value: '€${available.toStringAsFixed(2)}')),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(child: _Metric(label: 'Reserved', value: '€${reserved.toStringAsFixed(2)}')),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(child: _Metric(label: 'Write fee', value: '€${fee.toStringAsFixed(2)}')),
            ]),
            const SizedBox(height: B2BSpacing.lg),
            B2BSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Queue provisioning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: B2BSpacing.md),
              DropdownButtonFormField<String>(
                value: _deviceId,
                decoration: const InputDecoration(labelText: 'Card reader'),
                items: _devices.map((device) => DropdownMenuItem(value: _id(device), child: Text(device['label']?.toString().isNotEmpty == true ? device['label'].toString() : 'Card Reader'))).toList(),
                onChanged: (value) => setState(() => _deviceId = value),
              ),
              const SizedBox(height: B2BSpacing.md),
              DropdownButtonFormField<String>(
                value: _esimId,
                decoration: const InputDecoration(labelText: 'eSIM profile'),
                items: _esims.map((esim) => DropdownMenuItem(value: _id(esim), child: Text(_label(esim)))).toList(),
                onChanged: (value) => setState(() => _esimId = value),
              ),
              const SizedBox(height: B2BSpacing.md),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _submitting || _deviceId == null || _esimId == null ? null : _queue, icon: _submitting ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), label: Text(_submitting ? 'Queueing...' : 'Queue provisioning'))),
            ])),
            const SizedBox(height: B2BSpacing.lg),
            Text('Queue', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: B2BSpacing.sm),
            if (_loading) const B2BSurface(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())))
            else if (_jobs.isEmpty) const B2BSurface(child: Text('No remote provisioning jobs yet.', style: TextStyle(color: AppColors.textSecondary)))
            else for (final job in _jobs.take(20)) ...[
              B2BSurface(child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.radio_rounded, color: AppColors.primary), title: Text(job['status']?.toString() ?? 'queued', style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Job ${_id(job)} · ${job['esim_id'] ?? 'eSIM'}'), trailing: job['error_message'] != null ? const Icon(Icons.error_outline_rounded, color: AppColors.danger) : const Icon(Icons.chevron_right_rounded))),
              const SizedBox(height: B2BSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> _parseList(dynamic value) {
    final root = value is Map && value['data'] is Map ? Map<String, dynamic>.from(value['data'] as Map) : value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};
    final raw = root['results'] ?? root['data'] ?? value;
    return raw is List ? raw.whereType<Map>().map(Map<String, dynamic>.from).toList() : const [];
  }

  static String _id(Map<String, dynamic> item) => (item['device_id'] ?? item['id'] ?? item['esim_id'] ?? '').toString();
  static String _label(Map<String, dynamic> item) => (item['display_name'] ?? item['profile_name'] ?? item['plan_name'] ?? item['package_name'] ?? item['iccid'] ?? 'eSIM').toString();
  static double _number(dynamic value, {double fallback = 0}) => double.tryParse(value?.toString() ?? '') ?? fallback;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => B2BSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.credit_card_rounded, color: AppColors.primary), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700))]));
}
