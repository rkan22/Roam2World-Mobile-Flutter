import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'notification_rules.dart';
import 'notification_rules_repository.dart';

class NotificationRulesScreen extends StatefulWidget {
  const NotificationRulesScreen({super.key});

  @override
  State<NotificationRulesScreen> createState() => _NotificationRulesScreenState();
}

class _NotificationRulesScreenState extends State<NotificationRulesScreen> {
  final _repository = NotificationRulesRepository();
  List<NotificationRule> _rules = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rules = await _repository.fetchRules();
      if (!mounted) return;
      setState(() => _rules = rules);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Notification rules could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _rules.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repository.saveRules(_rules);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification rules saved.')),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _replace(int index, NotificationRule rule) {
    setState(() {
      final next = [..._rules];
      next[index] = rule;
      _rules = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _rules.where((rule) => rule.enabled).length;
    final high = _rules
        .where((rule) =>
            rule.enabled &&
            (rule.severity == 'high' || rule.severity == 'critical'))
        .length;
    final channels = _rules.expand((rule) => rule.channels).toSet().length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Notification Rules'),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
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
            Text('Operations alerts', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: B2BSpacing.xs),
            Text('Notification Rules', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Control which operational events require attention and how they are delivered.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading notification rules...')
            else if (_error != null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (_rules.isEmpty)
              const ContentEmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'No server-backed rules available',
                message: 'The notification rule service returned no configurable rules.',
              )
            else ...[
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Enabled', value: '$enabled', icon: Icons.check_circle_outline_rounded)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'High priority', value: '$high', icon: Icons.warning_amber_rounded)),
              ]),
              const SizedBox(height: B2BSpacing.sm),
              B2BMetricCard(label: 'Delivery channels', value: '$channels', icon: Icons.alternate_email_rounded),
              const SizedBox(height: B2BSpacing.lg),
              for (var index = 0; index < _rules.length; index++) ...[
                _RuleCard(
                  rule: _rules[index],
                  onChanged: (rule) => _replace(index, rule),
                ),
                const SizedBox(height: B2BSpacing.sm),
              ],
              const SizedBox(height: B2BSpacing.md),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save rules'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.onChanged});

  final NotificationRule rule;
  final ValueChanged<NotificationRule> onChanged;

  @override
  Widget build(BuildContext context) {
    final severityColor = switch (rule.severity) {
      'critical' => AppColors.danger,
      'high' => AppColors.warning,
      'medium' => AppColors.primary,
      _ => AppColors.textSecondary,
    };

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
                    Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                    if (rule.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(rule.description, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              Switch(
                value: rule.enabled,
                onChanged: (value) => onChanged(rule.copyWith(enabled: value)),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.sm),
          Wrap(
            spacing: B2BSpacing.xs,
            runSpacing: B2BSpacing.xs,
            children: [
              Chip(
                avatar: Icon(Icons.flag_outlined, size: 16, color: severityColor),
                label: Text(rule.severity.toUpperCase()),
              ),
              if (rule.unit.isNotEmpty)
                Chip(label: Text('${rule.threshold.toStringAsFixed(rule.threshold % 1 == 0 ? 0 : 1)} ${rule.unit}')),
            ],
          ),
          const SizedBox(height: B2BSpacing.sm),
          const Text('Channels', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: B2BSpacing.xs),
          Wrap(
            spacing: B2BSpacing.xs,
            children: [
              for (final channel in const ['in_app', 'email', 'sms'])
                FilterChip(
                  selected: rule.channels.contains(channel),
                  label: Text(_label(channel)),
                  onSelected: (selected) {
                    final next = {...rule.channels};
                    selected ? next.add(channel) : next.remove(channel);
                    onChanged(rule.copyWith(channels: next.toList()));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _label(String value) => switch (value) {
        'in_app' => 'In-app',
        'email' => 'Email',
        'sms' => 'SMS',
        _ => value,
      };
}
