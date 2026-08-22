import 'package:flutter/material.dart';

import '../../shared/widgets/r2w_toast.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'provider_retry_data.dart';
import 'provider_retry_repository.dart';

class ProviderRetryScreen extends StatefulWidget {
  const ProviderRetryScreen({super.key});

  @override
  State<ProviderRetryScreen> createState() => _ProviderRetryScreenState();
}

class _ProviderRetryScreenState extends State<ProviderRetryScreen> {
  final _repository = ProviderRetryRepository();
  ProviderRetryQueueData? _data;
  bool _loading = true;
  String? _error;
  String _filter = '';
  bool _busy = false;

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
      final data = await _repository.fetchQueue(
        status: _filter.isEmpty ? null : _filter,
      );
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Provider retry queue could not be loaded.');
      }
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

  Future<void> _runAction(ProviderRetryItem item, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      switch (action) {
        case 'retry':
          await _repository.triggerRetry(item.id);
          break;
        case 'schedule':
          await _repository.scheduleRetry(item.id, minutes: 5);
          break;
        case 'resolve':
          await _repository.resolve(item.id);
          break;
        case 'cancel':
          await _repository.cancel(item.id);
          break;
      }
      await _load();
      if (mounted) {
        R2WToast.success(context, 'Provider retry queue updated.');
      }
    } catch (error) {
      if (mounted) {
        R2WToast.error(context, 'Action failed: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Provider Retry Queue'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
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
            B2BSpacing.md,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            Text(
              'Provider recovery',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Live failed-provider queue with server-backed retry, scheduling, resolve and cancel actions.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && data == null)
              const ContentLoadingState(label: 'Loading retry queue...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              _summary(data.summary),
              const SizedBox(height: B2BSpacing.lg),
              _filters(),
              const SizedBox(height: B2BSpacing.md),
              if (data.items.isEmpty)
                const ContentEmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Queue is clear',
                  message: 'No provider retry records match this view.',
                )
              else
                for (final item in data.items) ...[
                  _item(item),
                  const SizedBox(height: B2BSpacing.sm),
                ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _summary(ProviderRetrySummary summary) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: B2BMetricCard(
              label: 'Pending',
              value: '${summary.pending}',
              icon: Icons.schedule_rounded,
            ),
          ),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(
            child: B2BMetricCard(
              label: 'Retrying',
              value: '${summary.retrying}',
              icon: Icons.sync_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: B2BSpacing.sm),
      Row(
        children: [
          Expanded(
            child: B2BMetricCard(
              label: 'Failed',
              value: '${summary.failed}',
              icon: Icons.error_outline_rounded,
            ),
          ),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(
            child: B2BMetricCard(
              label: 'Due now',
              value: '${summary.dueNow}',
              icon: Icons.bolt_rounded,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _filters() {
    const values = <String, String>{
      '': 'All',
      'pending': 'Pending',
      'retrying': 'Retrying',
      'failed': 'Failed',
      'resolved': 'Resolved',
      'cancelled': 'Cancelled',
    };
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: B2BSpacing.xs),
        itemBuilder: (context, index) {
          final entry = values.entries.elementAt(index);
          return ChoiceChip(
            label: Text(entry.value),
            selected: _filter == entry.key,
            onSelected: _busy
                ? null
                : (_) async {
                    setState(() => _filter = entry.key);
                    await _load();
                  },
          );
        },
      ),
    );
  }

  Widget _item(ProviderRetryItem item) {
    final color = switch (item.status.toLowerCase()) {
      'failed' => AppColors.danger,
      'retrying' => AppColors.warning,
      'resolved' => AppColors.success,
      'cancelled' => AppColors.textMuted,
      _ => AppColors.primary,
    };
    final detail = [
      if (item.provider.isNotEmpty) item.provider,
      if (item.category.isNotEmpty) item.category,
      'attempt ${item.attemptCount}/${item.maxAttempts}',
    ].join(' · ');
    return B2BSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.orderNumber.isEmpty
                      ? 'Retry #${item.id}'
                      : item.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _pill(item.status.isEmpty ? 'pending' : item.status, color),
            ],
          ),
          const SizedBox(height: B2BSpacing.xs),
          Text(detail, style: const TextStyle(color: AppColors.textSecondary)),
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: B2BSpacing.xs),
            Text(item.reason),
          ],
          if (item.lastError.isNotEmpty) ...[
            const SizedBox(height: B2BSpacing.xs),
            Text(
              item.lastError,
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: B2BSpacing.md),
          Wrap(
            spacing: B2BSpacing.xs,
            runSpacing: B2BSpacing.xs,
            children: [
              if (item.canRetry)
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _runAction(item, 'retry'),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Retry now'),
                ),
              if (item.canRetry)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _runAction(item, 'schedule'),
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text('Schedule 5m'),
                ),
              if (item.status != 'resolved' && item.status != 'cancelled')
                OutlinedButton(
                  onPressed: _busy ? null : () => _runAction(item, 'resolve'),
                  child: const Text('Resolve'),
                ),
              if (item.status != 'resolved' && item.status != 'cancelled')
                TextButton(
                  onPressed: _busy ? null : () => _runAction(item, 'cancel'),
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(B2BRadius.pill),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );
}
