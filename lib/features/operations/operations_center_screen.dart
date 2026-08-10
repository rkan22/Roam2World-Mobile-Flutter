import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/routing/app_role.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../auth/auth_repository.dart';
import 'operations_data.dart';
import 'operations_repository.dart';

class OperationsCenterScreen extends StatefulWidget {
  const OperationsCenterScreen({super.key});

  @override
  State<OperationsCenterScreen> createState() => _OperationsCenterScreenState();
}

class _OperationsCenterScreenState extends State<OperationsCenterScreen> {
  final _repository = OperationsRepository();
  final _authRepository = AuthRepository();
  final _search = TextEditingController();
  OperationsData? _data;
  AppRole _role = AppRole.unknown;
  bool _loading = true;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadRole();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final session = await _authRepository.readStoredProfile();
    if (!mounted) return;
    setState(() => _role = parseAppRole(session?.role));
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await _repository.fetchOperations();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'Operations data could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final reviewLogs = data?.logs.where((item) => item.needsReview).length ?? 0;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Operations Center'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.sm, B2BSpacing.lg, B2BSpacing.xxl),
          children: [
            Text('Operations control', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text('Failed orders, provider/API events and audit activity in one reseller workspace.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && data == null)
              const ContentLoadingState(label: 'Syncing operations...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Failed orders', value: '${data.failedOrders.length}', icon: Icons.error_outline_rounded)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Log events', value: '${data.logs.length}', icon: Icons.dns_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.sm),
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Needs review', value: '$reviewLogs', icon: Icons.warning_amber_rounded)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Audit events', value: '${data.auditEvents.length}', icon: Icons.shield_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.lg),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(width: B2BSpacing.xs),
                  itemBuilder: (context, index) => ChoiceChip(
                    label: Text(const ['Overview', 'Failed', 'API Logs', 'Audit'][index]),
                    selected: _tab == index,
                    onSelected: (_) => setState(() => _tab = index),
                  ),
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              if (_tab != 0) ...[
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(hintText: 'Search operations data', prefixIcon: Icon(Icons.search_rounded)),
                ),
                const SizedBox(height: B2BSpacing.md),
              ],
              if (_tab == 0) _overview(data),
              if (_tab == 1) _failed(data.failedOrders),
              if (_tab == 2) _logs(data.logs),
              if (_tab == 3) _audit(data.auditEvents),
            ],
          ],
        ),
      ),
    );
  }

  Widget _overview(OperationsData data) {
    final recent = data.auditEvents.take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_role == AppRole.admin) ...[
        B2BSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.business_center_outlined, color: AppColors.primary),
                title: const Text('Admin resellers', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Live reseller directory and active counts'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.adminResellers),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                title: const Text('Admin dealers', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Live dealer directory and active counts'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.adminDealers),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.insights_outlined, color: AppColors.primary),
                title: const Text('Pricing & reports', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Live admin pricing inventory and business totals'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.adminCommercial),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                title: const Text('Support & system health', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Admin support queue and backend health'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.support),
              ),
            ],
          ),
        ),
        const SizedBox(height: B2BSpacing.lg),
      ],
      B2BSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Queue health', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: B2BSpacing.md),
          _overviewRow('Failed provider/order queue', data.failedOrders.length, data.failedOrders.isEmpty ? AppColors.success : AppColors.danger),
          const Divider(height: B2BSpacing.xl),
          _overviewRow('API / webhook events needing review', data.logs.where((item) => item.needsReview).length, AppColors.warning),
        ]),
      ),
      const SizedBox(height: B2BSpacing.lg),
      Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: B2BSpacing.sm),
      if (recent.isEmpty)
        const ContentEmptyState(icon: Icons.history_rounded, title: 'No activity yet', message: 'Live operational activity will appear here.')
      else
        for (final item in recent) ...[
          _auditTile(item),
          const SizedBox(height: B2BSpacing.sm),
        ],
    ]);
  }

  Widget _failed(List<FailedOrderItem> items) {
    final q = _search.text.trim().toLowerCase();
    final visible = items.where((item) => q.isEmpty || '${item.provider} ${item.orderNumber} ${item.customer} ${item.packageName} ${item.status} ${item.error}'.toLowerCase().contains(q)).toList();
    if (visible.isEmpty) {
      return const ContentEmptyState(icon: Icons.task_alt_rounded, title: 'No failed orders', message: 'No live failed-order rows match this view.');
    }
    return Column(children: [
      for (final item in visible) ...[
        B2BSurface(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item.packageName, style: const TextStyle(fontWeight: FontWeight.w900))),
              _pill(item.priority, item.priority == 'Provider' ? AppColors.danger : AppColors.warning),
            ]),
            const SizedBox(height: B2BSpacing.xs),
            Text('${item.provider} · ${item.orderNumber}', style: const TextStyle(color: AppColors.textSecondary)),
            if (item.customer.isNotEmpty) Text(item.customer, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: B2BSpacing.sm),
            Text(item.error),
            const SizedBox(height: B2BSpacing.md),
            Row(children: [
              Text('${item.currency} ${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(item.status, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        const SizedBox(height: B2BSpacing.sm),
      ],
    ]);
  }

  Widget _logs(List<OperationLogItem> items) {
    final q = _search.text.trim().toLowerCase();
    final visible = items.where((item) => q.isEmpty || '${item.provider} ${item.type} ${item.endpoint} ${item.method} ${item.statusCode} ${item.message}'.toLowerCase().contains(q)).toList();
    if (visible.isEmpty) {
      return const ContentEmptyState(icon: Icons.dns_outlined, title: 'No live log events', message: 'Provider and webhook events will appear when backend log sources return data.');
    }
    return Column(children: [
      for (final item in visible) ...[
        B2BSurface(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(item.needsReview ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: item.needsReview ? AppColors.warning : AppColors.success),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item.method} ${item.endpoint.isEmpty ? 'Operational event' : item.endpoint}', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text('${item.provider} · ${item.type}', style: const TextStyle(color: AppColors.textSecondary)),
              if (item.message.isNotEmpty) Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: B2BSpacing.xs),
              Text('${item.statusCode == 0 ? 'N/A' : item.statusCode} · ${item.durationMs}ms${_date(item.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
            ])),
          ]),
        ),
        const SizedBox(height: B2BSpacing.sm),
      ],
    ]);
  }

  Widget _audit(List<AuditEventItem> items) {
    final q = _search.text.trim().toLowerCase();
    final visible = items.where((item) => q.isEmpty || '${item.actor} ${item.action} ${item.target} ${item.source} ${item.description}'.toLowerCase().contains(q)).toList();
    if (visible.isEmpty) {
      return const ContentEmptyState(icon: Icons.shield_outlined, title: 'No audit events', message: 'No dedicated or composed activity matches this view.');
    }
    return Column(children: [
      for (final item in visible) ...[
        _auditTile(item),
        const SizedBox(height: B2BSpacing.sm),
      ],
    ]);
  }

  Widget _auditTile(AuditEventItem item) => B2BSurface(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.success),
          const SizedBox(width: B2BSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item.actor, style: const TextStyle(fontWeight: FontWeight.w900))),
              _pill(item.source, AppColors.success),
            ]),
            const SizedBox(height: 3),
            Text('${item.action} · ${item.target}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (item.description.isNotEmpty) Text(item.description, style: const TextStyle(color: AppColors.textSecondary)),
            Text(_date(item.createdAt, prefix: ''), style: Theme.of(context).textTheme.bodySmall),
          ])),
        ]),
      );

  Widget _overviewRow(String label, int value, Color color) => Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        _pill('$value', color),
      ]);

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(B2BRadius.pill)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
      );

  String _date(DateTime? value, {String prefix = ' · '}) =>
      value == null ? '' : '$prefix${DateFormat('dd MMM, HH:mm').format(value.toLocal())}';
}
