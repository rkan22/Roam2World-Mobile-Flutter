import 'dart:convert';

import 'package:flutter/material.dart';

import '../../shared/widgets/r2w_toast.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'admin_governance_repository.dart';

class AdminGovernanceScreen extends StatefulWidget {
  const AdminGovernanceScreen({super.key});

  @override
  State<AdminGovernanceScreen> createState() => _AdminGovernanceScreenState();
}

class _AdminGovernanceScreenState extends State<AdminGovernanceScreen> {
  final _repository = AdminGovernanceRepository();
  AdminGovernanceData? _data;
  bool _loading = true;
  String? _error;

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
      final data = await _repository.fetchAll();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Governance configuration could not be loaded.',
        );
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

  Future<void> _edit(
    String title,
    Map<String, dynamic> value,
    Future<Map<String, dynamic>> Function(Map<String, dynamic>) save,
  ) async {
    final controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(value),
    );
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            minLines: 12,
            maxLines: 20,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'Configuration JSON',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (submitted == null) return;
    try {
      final decoded = jsonDecode(submitted);
      if (decoded is! Map) throw const FormatException();
      await save(Map<String, dynamic>.from(decoded));
      if (!mounted) return;
      R2WToast.success(context, 'Governance configuration saved.');
      await _load();
    } catch (_) {
      if (!mounted) return;
      R2WToast.error(
        context,
        'Invalid JSON or server rejected the configuration.',
      );
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
        title: const Text('Governance'),
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
              'Platform governance',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Live role, account and catalog governance stored by the backend.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && data == null)
              const ContentLoadingState(label: 'Loading governance...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              _section(
                'Role permissions',
                Icons.admin_panel_settings_outlined,
                data.rolePermissions,
                () => _edit(
                  'Role permissions',
                  data.rolePermissions,
                  _repository.saveRolePermissions,
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              _section(
                'Account governance',
                Icons.manage_accounts_outlined,
                data.accountGovernance,
                () => _edit(
                  'Account governance',
                  data.accountGovernance,
                  _repository.saveAccountGovernance,
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              _section(
                'Catalog governance',
                Icons.inventory_2_outlined,
                data.catalogGovernance,
                () => _edit(
                  'Catalog governance',
                  data.catalogGovernance,
                  _repository.saveCatalogGovernance,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(
    String title,
    IconData icon,
    Map<String, dynamic> value,
    VoidCallback edit,
  ) {
    final preview = const JsonEncoder.withIndent('  ').convert(value);
    return B2BSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: edit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(B2BSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(B2BRadius.md),
            ),
            child: SelectableText(
              preview,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
