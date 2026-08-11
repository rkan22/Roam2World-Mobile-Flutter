import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'admin_partners_data.dart';
import 'admin_partners_repository.dart';

enum AdminPartnerType { resellers, dealers }

class AdminPartnersScreen extends StatefulWidget {
  const AdminPartnersScreen({super.key, required this.type});

  final AdminPartnerType type;

  @override
  State<AdminPartnersScreen> createState() => _AdminPartnersScreenState();
}

class _AdminPartnersScreenState extends State<AdminPartnersScreen> {
  final _repository = AdminPartnersRepository();
  final _search = TextEditingController();
  AdminPartnerList? _data;
  bool _loading = true;
  String? _error;

  String get _title =>
      widget.type == AdminPartnerType.resellers ? 'Resellers' : 'Dealers';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = widget.type == AdminPartnerType.resellers
          ? await _repository.fetchResellers()
          : await _repository.fetchDealers();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = '$_title could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editMarkup(AdminPartnerItem item) async {
    final controller = TextEditingController(
      text: item.markupPercentage.toStringAsFixed(2),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit ${widget.type == AdminPartnerType.resellers ? 'reseller' : 'dealer'} markup',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Markup percentage',
            suffixText: '%',
            helperText: 'Allowed range: 0–100',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (parsed != null && parsed >= 0 && parsed <= 100) {
                Navigator.pop(context, parsed);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    try {
      if (widget.type == AdminPartnerType.resellers) {
        await _repository.updateResellerMarkup(
          resellerId: item.id,
          markupPercentage: value,
        );
      } else {
        await _repository.updateDealerMarkup(
          dealerId: item.id,
          markupPercentage: value,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Markup updated successfully.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Markup could not be updated: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final query = _search.text.trim().toLowerCase();
    final visible =
        data?.items
            .where(
              (item) =>
                  query.isEmpty ||
                  item.companyName.toLowerCase().contains(query),
            )
            .toList(growable: false) ??
        const <AdminPartnerItem>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/operations'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Admin $_title'),
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
            B2BSpacing.sm,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            Text(
              '$_title workspace',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            Text(
              'Live admin directory from the mobile backend.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && data == null)
              ContentLoadingState(label: 'Loading $_title...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              Row(
                children: [
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Total',
                      value: '${data.total}',
                      icon: Icons.groups_2_outlined,
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: B2BMetricCard(
                      label: 'Active',
                      value: '${data.active}',
                      icon: Icons.verified_user_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.lg),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search ${_title.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _search.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              if (visible.isEmpty)
                ContentEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No ${_title.toLowerCase()} found',
                  message: query.isEmpty
                      ? 'The backend returned no partner rows.'
                      : 'No partner matches your search.',
                )
              else
                for (final item in visible) ...[
                  _PartnerTile(
                    item: item,
                    onEditMarkup: () => _editMarkup(item),
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PartnerTile extends StatelessWidget {
  const _PartnerTile({required this.item, required this.onEditMarkup});

  final AdminPartnerItem item;
  final VoidCallback onEditMarkup;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isActive ? AppColors.success : AppColors.textMuted;
    return B2BSurface(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(B2BRadius.md),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: B2BSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.companyName.isEmpty
                      ? 'Partner #${item.id}'
                      : item.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  item.createdAt == null
                      ? 'ID ${item.id}'
                      : 'ID ${item.id} · ${item.createdAt!.toLocal().toIso8601String().split('T').first}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(B2BRadius.pill),
                ),
                child: Text(
                  item.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              TextButton(
                onPressed: onEditMarkup,
                child: Text(
                  '${item.markupPercentage.toStringAsFixed(2)}% markup',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
