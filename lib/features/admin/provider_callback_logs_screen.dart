import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'provider_callback_logs_repository.dart';

class ProviderCallbackLogsScreen extends StatefulWidget {
  const ProviderCallbackLogsScreen({super.key});

  @override
  State<ProviderCallbackLogsScreen> createState() =>
      _ProviderCallbackLogsScreenState();
}

class _ProviderCallbackLogsScreenState
    extends State<ProviderCallbackLogsScreen> {
  final _repository = ProviderCallbackLogsRepository();
  List<ProviderCallbackLogItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final items = await _repository.fetchLogs();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Provider callback logs could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/dashboard');
  }

  Future<void> _markProcessed(ProviderCallbackLogItem item) async {
    try {
      await _repository.updateStatus(item.id, 'processed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Callback marked processed.')),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Callback status could not be updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final failed = _items
        .where((item) => item.status.toLowerCase() == 'failed')
        .length;
    final invalidSignatures = _items
        .where((item) => item.signatureValid == false)
        .length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Provider Callback Logs'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.md,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            Text(
              'Callback operations',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Live provider callback records from the mobile admin API.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && _items.isEmpty)
              const ContentLoadingState(label: 'Loading callback logs...')
            else if (_error != null && _items.isEmpty)
              ContentErrorState(message: _error!, onRetry: _load)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Callbacks',
                      value: '${_items.length}',
                      icon: Icons.webhook_outlined,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Failed',
                      value: '$failed',
                      icon: Icons.error_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.sm),
              B2BMetricCard(
                label: 'Invalid signatures',
                value: '$invalidSignatures',
                icon: Icons.gpp_bad_outlined,
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (_items.isEmpty)
                const ContentEmptyState(
                  icon: Icons.webhook_outlined,
                  title: 'No callback logs',
                  message: 'The backend returned no provider callback records.',
                )
              else
                ..._items.map(_tile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(ProviderCallbackLogItem item) {
    final subtitle = [
      if (item.eventType.isNotEmpty) item.eventType,
      if (item.providerOrderId.isNotEmpty) 'Order ${item.providerOrderId}',
      if (item.iccid.isNotEmpty) 'ICCID ${item.iccid}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: B2BSpacing.sm),
      child: B2BSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.provider.isEmpty ? 'Unknown provider' : item.provider,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  item.status,
                  style: TextStyle(
                    color: item.status.toLowerCase() == 'failed'
                        ? AppColors.danger
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: B2BSpacing.xs),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (item.signatureValid != null) ...[
              const SizedBox(height: B2BSpacing.xs),
              Text(
                item.signatureValid! ? 'Signature valid' : 'Signature invalid',
                style: TextStyle(
                  color: item.signatureValid!
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
            ],
            if (item.errorMessage.isNotEmpty) ...[
              const SizedBox(height: B2BSpacing.xs),
              Text(
                item.errorMessage,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            if (item.status.toLowerCase() != 'processed') ...[
              const SizedBox(height: B2BSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _markProcessed(item),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Mark processed'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
