import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'manual_fulfillment_repository.dart';

class ManualFulfillmentScreen extends StatefulWidget {
  const ManualFulfillmentScreen({super.key});

  @override
  State<ManualFulfillmentScreen> createState() => _ManualFulfillmentScreenState();
}

class _ManualFulfillmentScreenState extends State<ManualFulfillmentScreen> {
  final _repository = ManualFulfillmentRepository();
  ManualFulfillmentWorkspaceData? _data;
  bool _loading = true;
  String? _error;
  int _tab = 0;

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
      final data = await _repository.fetchWorkspace();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'Manual fulfillment data could not be loaded.');
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

  Future<String?> _ask(String title, String hint, {bool multiline = false}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: multiline ? 4 : 1,
          maxLines: multiline ? 8 : 1,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The server action could not be completed.')),
      );
    }
  }

  Future<void> _addSims() async {
    final raw = await _ask('Add blank SIM ICCIDs', 'One ICCID per line', multiline: true);
    if (raw == null || raw.trim().isEmpty) return;
    final iccids = raw
        .replaceAll(',', '\n')
        .split('\n')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    await _run(() => _repository.addBlankSims(iccids), 'SIM inventory updated.');
  }

  Future<void> _assignQr(ManualTaskItem task) async {
    final code = await _ask('Assign QR / LPA code', 'LPA:1$... or QR value', multiline: true);
    if (code == null || code.isEmpty) return;
    await _run(() => _repository.assignQr(task.taskId, code: code), 'QR delivery completed.');
  }

  Future<void> _activateSim(ManualTaskItem task) async {
    final reference = await _ask('Activate physical SIM', 'Supplier activation reference (optional)');
    if (reference == null) return;
    await _run(
      () => _repository.activateSim(task.taskId, activationReference: reference),
      'SIM activation completed.',
    );
  }

  Future<void> _cancel(ManualTaskItem task) async {
    final reason = await _ask('Cancel manual request', 'Reason for cancellation');
    if (reason == null) return;
    await _run(() => _repository.cancelTask(task.taskId, reason: reason), 'Task cancelled.');
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final pending = data?.tasks.where((item) => !item.isFinished).length ?? 0;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Manual Fulfillment'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.md, B2BSpacing.lg, B2BSpacing.xxl),
          children: [
            Text('Manual delivery operations', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Live manual eSIM/SIM products, stock and fulfillment tasks from the backend.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && data == null)
              const ContentLoadingState(label: 'Loading manual fulfillment...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Products', value: '${data.products.length}', icon: Icons.inventory_2_outlined)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Pending tasks', value: '$pending', icon: Icons.pending_actions_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.sm),
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Blank SIMs', value: '${data.availableBlankStock}', icon: Icons.sim_card_outlined)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Total tasks', value: '${data.tasks.length}', icon: Icons.assignment_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.lg),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Tasks')),
                  ButtonSegment(value: 1, label: Text('Products')),
                  ButtonSegment(value: 2, label: Text('SIM stock')),
                ],
                selected: {_tab},
                onSelectionChanged: (value) => setState(() => _tab = value.first),
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (_tab == 0) _tasks(data.tasks),
              if (_tab == 1) _products(data.products),
              if (_tab == 2) _inventory(data),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tasks(List<ManualTaskItem> tasks) {
    if (tasks.isEmpty) {
      return const ContentEmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'No manual tasks',
        message: 'Manual fulfillment requests will appear here.',
      );
    }
    return Column(children: [
      for (final task in tasks) ...[
        B2BSurface(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(task.productName, style: const TextStyle(fontWeight: FontWeight.w900))),
              _pill(task.status),
            ]),
            const SizedBox(height: B2BSpacing.xs),
            Text('${task.orderNumber} · ${task.productType.toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary)),
            if (task.customerName.isNotEmpty) Text(task.customerName),
            if (task.customerEmail.isNotEmpty) Text(task.customerEmail, style: Theme.of(context).textTheme.bodySmall),
            if (task.iccid.isNotEmpty) Text('ICCID ${task.iccid}', style: Theme.of(context).textTheme.bodySmall),
            if (task.errorMessage.isNotEmpty) ...[
              const SizedBox(height: B2BSpacing.xs),
              Text(task.errorMessage, style: const TextStyle(color: AppColors.danger)),
            ],
            if (!task.isFinished) ...[
              const SizedBox(height: B2BSpacing.md),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (task.canSendToFlexnet)
                  OutlinedButton.icon(
                    onPressed: () => _run(() => _repository.sendToFlexnet(task.taskId), 'Sent to Flexnet.'),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Send Flexnet'),
                  ),
                if (task.productType == 'esim')
                  FilledButton.tonalIcon(
                    onPressed: () => _assignQr(task),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Assign QR'),
                  ),
                if (task.productType == 'sim')
                  FilledButton.tonalIcon(
                    onPressed: () => _activateSim(task),
                    icon: const Icon(Icons.sim_card_download_outlined),
                    label: const Text('Activate SIM'),
                  ),
                TextButton.icon(
                  onPressed: () => _cancel(task),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: B2BSpacing.sm),
      ],
    ]);
  }

  Widget _products(List<ManualProductItem> products) {
    if (products.isEmpty) {
      return const ContentEmptyState(icon: Icons.inventory_2_outlined, title: 'No manual products', message: 'No manual products were returned.');
    }
    return B2BSurface(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < products.length; i++) ...[
          ListTile(
            leading: Icon(products[i].type == 'sim' ? Icons.sim_card_outlined : Icons.qr_code_2_rounded),
            title: Text(products[i].name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${products[i].operatorName} · ${products[i].packageId}'),
            trailing: Text('${products[i].currency} ${products[i].providerCost.toStringAsFixed(2)}'),
          ),
          if (i != products.length - 1) const Divider(height: 1),
        ],
      ]),
    );
  }

  Widget _inventory(ManualFulfillmentWorkspaceData data) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(onPressed: _addSims, icon: const Icon(Icons.add_rounded), label: const Text('Add blank SIM ICCIDs')),
      const SizedBox(height: B2BSpacing.md),
      if (data.inventory.isEmpty)
        const ContentEmptyState(icon: Icons.sim_card_alert_outlined, title: 'No SIM inventory', message: 'Add blank physical SIM ICCIDs to the shared stock pool.')
      else
        B2BSurface(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < data.inventory.length; i++) ...[
              ListTile(
                leading: const Icon(Icons.sim_card_outlined),
                title: Text(data.inventory[i].iccid, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: data.inventory[i].orderNumber.isEmpty ? null : Text(data.inventory[i].orderNumber),
                trailing: Text(data.inventory[i].status),
              ),
              if (i != data.inventory.length - 1) const Divider(height: 1),
            ],
          ]),
        ),
    ]);
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(B2BRadius.pill),
        ),
        child: Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900)),
      );
}
