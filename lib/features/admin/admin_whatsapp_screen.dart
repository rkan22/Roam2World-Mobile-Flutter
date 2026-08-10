import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'admin_whatsapp_data.dart';
import 'admin_whatsapp_repository.dart';

class AdminWhatsAppScreen extends StatefulWidget {
  const AdminWhatsAppScreen({super.key});

  @override
  State<AdminWhatsAppScreen> createState() => _AdminWhatsAppScreenState();
}

class _AdminWhatsAppScreenState extends State<AdminWhatsAppScreen> {
  final _repository = AdminWhatsAppRepository();
  AdminWhatsAppData? _data;
  Map<String, bool> _featured = const {};
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
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await _repository.fetch();
      if (!mounted) return;
      setState(() {
        _data = data;
        _featured = {
          for (final item in data.catalog) item.packageId: item.featured,
        };
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final data = _data;
    if (data == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await _repository.updateFeatured(data.catalog, _featured);
      if (!mounted) return;
      setState(() => _data = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp catalog updated.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final delivered =
        data?.delivery.values.fold<int>(0, (sum, value) => sum + value) ?? 0;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('WhatsApp Workspace'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
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
            B2BSpacing.sm,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            Text(
              'WhatsApp commerce',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Connection readiness, delivery events, templates, catalog pricing and manual approvals.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && data == null)
              const ContentLoadingState(label: 'Loading WhatsApp workspace...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              Row(
                children: [
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Catalog',
                      value: '${data.catalog.length}',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Delivery events',
                      value: '$delivered',
                      icon: Icons.send_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Templates',
                      value: '${data.templates.length}',
                      icon: Icons.message_outlined,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Manual approvals',
                      value: '${data.manualApprovals.length}',
                      icon: Icons.approval_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.lg),
              B2BSurface(
                child: Row(
                  children: [
                    Icon(
                      data.connection.isReady
                          ? Icons.check_circle_outline_rounded
                          : Icons.warning_amber_rounded,
                      color: data.connection.isReady
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: B2BSpacing.sm),
                    Expanded(
                      child: Text(
                        data.connection.isReady
                            ? 'Meta WhatsApp connection is ready.'
                            : 'Meta WhatsApp configuration needs review.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: B2BSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Customer catalog',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save featured'),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.sm),
              if (data.catalog.isEmpty)
                const ContentEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No eligible packages',
                  message:
                      'Packages appear after WhatsApp customer pricing is configured.',
                )
              else
                B2BSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < data.catalog.length;
                        index++
                      ) ...[
                        SwitchListTile(
                          value:
                              _featured[data.catalog[index].packageId] ??
                              data.catalog[index].featured,
                          onChanged: _saving
                              ? null
                              : (value) => setState(
                                  () => _featured = {
                                    ..._featured,
                                    data.catalog[index].packageId: value,
                                  },
                                ),
                          title: Text(
                            data.catalog[index].packageName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${data.catalog[index].provider} · ${data.catalog[index].customerPrice == null ? 'Price unavailable' : 'USD ${data.catalog[index].customerPrice!.toStringAsFixed(2)}'}',
                          ),
                        ),
                        if (index != data.catalog.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
