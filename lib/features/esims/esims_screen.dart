import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import 'esim_catalog.dart';
import 'esims_repository.dart';

class EsimsScreen extends StatefulWidget {
  const EsimsScreen({super.key});

  @override
  State<EsimsScreen> createState() => _EsimsScreenState();
}

class _EsimsScreenState extends State<EsimsScreen> {
  final _repository = EsimsRepository();
  final _searchController = TextEditingController();
  final tabs = const ['All', 'Active', 'Expired', 'Installed'];

  Timer? _searchTimer;
  int selectedTab = 0;
  bool _loading = true;
  String? _error;
  List<MobileEsim> _esims = const [];

  String? get _status => switch (selectedTab) {
        1 => 'active',
        2 => 'expired',
        3 => 'installed',
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 450), _load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.fetchEsims(
        search: _searchController.text,
        status: _status,
      );
      if (!mounted) return;
      setState(() => _esims = result.esims);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'eSIMs could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _activeCount => _esims.where((e) {
        final value = e.status.toLowerCase();
        return value == 'active' || value == 'activated';
      }).length;

  int get _readyCount => _esims.where((e) => e.hasQr).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 2),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('eSIM Workspace', style: theme.textTheme.headlineLarge),
                        const SizedBox(height: 5),
                        Text('Manage customer provisioning and lifecycle.', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'eSIM history',
                    onPressed: () => context.push('/esims/history'),
                    icon: const Icon(Icons.history_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _SummaryCard(label: 'Total eSIMs', value: '${_esims.length}', icon: Icons.sim_card_rounded, color: AppColors.primary, soft: AppColors.primaryLight)),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryCard(label: 'Active', value: '$_activeCount', icon: Icons.bolt_rounded, color: AppColors.success, soft: AppColors.successSoft)),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryCard(label: 'QR ready', value: '$_readyCount', icon: Icons.qr_code_2_rounded, color: AppColors.sky, soft: const Color(0xFFEAF7FE))),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search customer, ICCID or package',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tabs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ChoiceChip(
                    label: Text(tabs[index]),
                    selected: selectedTab == index,
                    onSelected: (_) {
                      setState(() => selectedTab = index);
                      _load();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const ContentLoadingState(label: 'Loading eSIMs...')
              else if (_error != null)
                ContentErrorState(message: _error!, onRetry: _load)
              else if (_esims.isEmpty)
                ContentEmptyState(
                  icon: Icons.sim_card_outlined,
                  title: 'No eSIMs found',
                  message: 'Try another search or status filter.',
                  actionLabel: 'Clear filters',
                  onAction: () {
                    _searchController.clear();
                    setState(() => selectedTab = 0);
                    _load();
                  },
                )
              else
                for (var index = 0; index < _esims.length; index++) ...[
                  _EsimCard(
                    esim: _esims[index],
                    onTap: () => context.push('/esims/detail', extra: _esims[index]),
                  ),
                  if (index != _esims.length - 1) const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color, required this.soft});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 10),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontSize: 19)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EsimCard extends StatelessWidget {
  const _EsimCard({required this.esim, required this.onTap});

  final MobileEsim esim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = esim.status.toLowerCase();
    final active = value == 'active' || value == 'activated';
    final expired = value.contains('expired');
    final color = active ? AppColors.success : expired ? AppColors.warning : AppColors.primary;
    final soft = active ? AppColors.successSoft : expired ? AppColors.warningSoft : AppColors.primaryLight;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(B2BRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(B2BRadius.xl),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.sim_card_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(esim.packageName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(esim.customerName.isEmpty ? esim.provider : esim.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(999)),
                    child: Text(esim.status, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11.5)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _InfoLine(label: 'ICCID', value: esim.iccid.isEmpty ? 'Pending provisioning' : esim.iccid),
                    const SizedBox(height: 9),
                    _InfoLine(label: 'Provider', value: esim.provider.isEmpty ? 'Roam2World' : esim.provider),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: esim.hasQr ? AppColors.accentSoft : AppColors.warningSoft, borderRadius: BorderRadius.circular(11)),
                    child: Icon(esim.hasQr ? Icons.qr_code_2_rounded : Icons.hourglass_top_rounded, size: 18, color: esim.hasQr ? AppColors.accent : AppColors.warning),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(esim.hasQr ? 'Installation package ready' : 'Provisioning in progress', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700))),
                  Text('Manage', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(width: 64, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
        ],
      );
}
