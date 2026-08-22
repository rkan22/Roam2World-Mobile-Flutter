import 'package:flutter/material.dart';

import '../../shared/widgets/r2w_toast.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'admin_routing_repository.dart';

class AdminRoutingScreen extends StatefulWidget {
  const AdminRoutingScreen({super.key});

  @override
  State<AdminRoutingScreen> createState() => _AdminRoutingScreenState();
}

class _AdminRoutingScreenState extends State<AdminRoutingScreen> {
  final _repository = AdminRoutingRepository();
  List<AdminRoutingRule> _rules = const [];
  bool _loading = true;
  String? _error;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _rules.isEmpty;
      _error = null;
    });
    try {
      final rules = await _repository.fetchRules();
      if (mounted) setState(() => _rules = rules);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Provider routing rules could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(AdminRoutingRule rule, String action) async {
    setState(() => _busyId = rule.id);
    try {
      await _repository.override(action: action, rule: rule);
      await _load();
      if (mounted) {
        R2WToast.success(context, '${rule.provider}: $action completed');
      }
    } catch (_) {
      if (mounted) {
        R2WToast.error(context, 'Routing action failed.');
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final primary = _rules.where((rule) => rule.isPrimary).length;
    final active = _rules.where((rule) => rule.isActive).length;
    final categories = _rules
        .map((rule) => rule.category)
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Provider Routing'),
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
              'B2B provider routing',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Live route priority and provider override controls from the mobile admin API.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && _rules.isEmpty)
              const ContentLoadingState(label: 'Loading routing rules...')
            else if (_error != null && _rules.isEmpty)
              ContentErrorState(message: _error!, onRetry: _load)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Rules',
                      value: '${_rules.length}',
                      icon: Icons.route_outlined,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Active',
                      value: '$active',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Primary',
                      value: '$primary',
                      icon: Icons.star_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Categories',
                      value: '$categories',
                      icon: Icons.category_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (_rules.isEmpty)
                const ContentEmptyState(
                  icon: Icons.route_outlined,
                  title: 'No routing rules',
                  message:
                      'The backend returned no mobile provider route rules.',
                )
              else
                for (final rule in _rules) ...[
                  _ruleCard(rule),
                  const SizedBox(height: B2BSpacing.sm),
                ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _ruleCard(AdminRoutingRule rule) {
    final busy = _busyId == rule.id;
    return B2BSurface(
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
                      rule.displayName.isEmpty
                          ? rule.provider
                          : rule.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${rule.category} · priority ${rule.priority}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (rule.isPrimary)
                const Chip(label: Text('Primary'))
              else if (!rule.isActive)
                const Chip(label: Text('Disabled')),
            ],
          ),
          const SizedBox(height: B2BSpacing.sm),
          Text(
            'Fallback: ${rule.allowFallback ? 'enabled' : 'disabled'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (rule.markupPercent != null ||
              rule.resellerMarkupPercent != null ||
              rule.dealerMarkupPercent != null) ...[
            const SizedBox(height: 4),
            Text(
              'Markup · base ${_pct(rule.markupPercent)} · reseller ${_pct(rule.resellerMarkupPercent)} · dealer ${_pct(rule.dealerMarkupPercent)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: B2BSpacing.md),
          if (busy)
            const LinearProgressIndicator()
          else
            Wrap(
              spacing: B2BSpacing.xs,
              runSpacing: B2BSpacing.xs,
              children: [
                if (!rule.isPrimary && rule.isActive)
                  FilledButton.tonal(
                    onPressed: () => _run(rule, 'set_primary'),
                    child: const Text('Set primary'),
                  ),
                if (rule.isActive)
                  OutlinedButton(
                    onPressed: () => _run(rule, 'disable_provider'),
                    child: const Text('Disable'),
                  )
                else
                  FilledButton.tonal(
                    onPressed: () => _run(rule, 'enable_provider'),
                    child: const Text('Enable'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _pct(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(2)}%';
}
