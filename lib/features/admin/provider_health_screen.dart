import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'provider_health_repository.dart';

class ProviderHealthScreen extends StatefulWidget {
  const ProviderHealthScreen({super.key});

  @override
  State<ProviderHealthScreen> createState() => _ProviderHealthScreenState();
}

class _ProviderHealthScreenState extends State<ProviderHealthScreen> {
  final _repository = ProviderHealthRepository();
  ProviderHealthData? _data;
  bool _loading = true;
  bool _liveChecking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool liveCheck = false}) async {
    setState(() {
      _loading = _data == null;
      _liveChecking = liveCheck;
      _error = null;
    });
    try {
      final data = await _repository.fetch(liveCheck: liveCheck);
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'Provider health could not be loaded.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _liveChecking = false;
        });
      }
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/dashboard');
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'ok':
        return AppColors.success;
      case 'warning':
      case 'configured_adapter_pending':
        return AppColors.warning;
      case 'error':
      case 'degraded':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Provider Health'),
        actions: [IconButton(onPressed: () => _load(), icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.md, B2BSpacing.lg, B2BSpacing.xxl),
          children: [
            Text('Provider operations', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Live provider configuration, route availability and recent backend health state.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.md),
            FilledButton.icon(
              onPressed: _liveChecking ? null : () => _load(liveCheck: true),
              icon: _liveChecking
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.monitor_heart_outlined),
              label: Text(_liveChecking ? 'Running live checks...' : 'Run live provider checks'),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && data == null)
              const ContentLoadingState(label: 'Loading provider health...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              _summary(data),
              const SizedBox(height: B2BSpacing.xl),
              Text('Providers', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: B2BSpacing.sm),
              if (data.providers.isEmpty)
                const ContentEmptyState(
                  icon: Icons.hub_outlined,
                  title: 'No providers',
                  message: 'The provider health endpoint returned no provider records.',
                )
              else
                ...data.providers.map(_providerCard),
              const SizedBox(height: B2BSpacing.xl),
              Text('Route health', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: B2BSpacing.sm),
              if (data.routes.isEmpty)
                const ContentEmptyState(
                  icon: Icons.route_outlined,
                  title: 'No route data',
                  message: 'The backend returned no provider route health records.',
                )
              else
                ...data.routes.map(_routeCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summary(ProviderHealthData data) {
    final summary = data.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: B2BMetricCard(label: 'Online', value: '${summary.online}', icon: Icons.check_circle_outline_rounded)),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(child: B2BMetricCard(label: 'Degraded', value: '${summary.degraded}', icon: Icons.warning_amber_rounded)),
        ]),
        const SizedBox(height: B2BSpacing.sm),
        Row(children: [
          Expanded(child: B2BMetricCard(label: 'Routable', value: '${summary.routableCategories}', icon: Icons.route_outlined)),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(child: B2BMetricCard(label: 'Unroutable', value: '${summary.unroutableCategories}', icon: Icons.block_outlined)),
        ]),
        const SizedBox(height: B2BSpacing.sm),
        B2BSurface(
          child: Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: _statusColor(data.healthStatus)),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(child: Text('Overall health: ${data.healthStatus}', style: const TextStyle(fontWeight: FontWeight.w900))),
              Text('${summary.categoriesUsingFallback} fallback', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _providerCard(ProviderHealthItem item) {
    final details = [
      item.configured ? 'configured' : 'not configured',
      item.adapterReady ? 'adapter ready' : 'adapter pending',
      if (item.totalOrders > 0) '${item.totalOrders} orders',
      if (item.failedOrders > 0) '${item.failedOrders} failed',
      if (item.latencyMs != null) '${item.latencyMs} ms',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: B2BSpacing.sm),
      child: B2BSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.w900))),
              Text(item.status, style: TextStyle(color: _statusColor(item.status), fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: B2BSpacing.xs),
            Text(details, style: const TextStyle(color: AppColors.textSecondary)),
            if (item.supports.isNotEmpty) ...[
              const SizedBox(height: B2BSpacing.xs),
              Text(item.supports.join(' · '), style: Theme.of(context).textTheme.bodySmall),
            ],
            if (item.error.isNotEmpty) ...[
              const SizedBox(height: B2BSpacing.xs),
              Text(item.error, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeCard(ProviderRouteHealthItem item) {
    final fallback = item.fallbackProviders.isEmpty ? 'No fallback' : 'Fallback: ${item.fallbackProviders.join(', ')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: B2BSpacing.sm),
      child: B2BSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.w900))),
              Text(item.healthStatus, style: TextStyle(color: _statusColor(item.healthStatus), fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: B2BSpacing.xs),
            Text('Primary: ${item.primaryProvider}${item.primaryOnline ? ' · online' : ' · unavailable'}'),
            Text(fallback, style: const TextStyle(color: AppColors.textSecondary)),
            if (item.actionRequired.isNotEmpty) ...[
              const SizedBox(height: B2BSpacing.xs),
              Text(item.actionRequired.join(' '), style: const TextStyle(color: AppColors.warning)),
            ],
          ],
        ),
      ),
    );
  }
}
