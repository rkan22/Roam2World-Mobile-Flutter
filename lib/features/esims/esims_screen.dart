import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
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
  final _tabs = const ['All', 'Active', 'Pending', 'Expired', 'Installed'];

  Timer? _searchTimer;
  int _selectedTab = 0;
  String _kind = 'all';
  String _provider = 'all';
  bool _loading = true;
  String? _error;
  List<MobileEsim> _esims = const [];

  String? get _status => switch (_selectedTab) {
        1 => 'active',
        2 => 'pending',
        3 => 'expired',
        4 => 'installed',
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
      setState(() => _error = 'SIM & eSIM inventory could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MobileEsim> get _visible {
    return _esims.where((item) {
      if (_kind == 'esim' && item.isPhysicalSim) return false;
      if (_kind == 'physical_sim' && !item.isPhysicalSim) return false;
      if (_provider != 'all' && _providerKey(item.provider) != _provider) return false;
      return true;
    }).toList(growable: false);
  }

  List<String> get _providers {
    final values = _esims
        .map((item) => _providerKey(item.provider))
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  int get _activeFilterCount =>
      (_kind == 'all' ? 0 : 1) + (_provider == 'all' ? 0 : 1);

  Future<void> _openFilters() async {
    var draftKind = _kind;
    var draftProvider = _provider;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.lg,
            B2BSpacing.lg,
            B2BSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Inventory filters', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setSheetState(() {
                      draftKind = 'all';
                      draftProvider = 'all';
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.lg),
              Text('Line type', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: B2BSpacing.sm),
              Wrap(
                spacing: B2BSpacing.sm,
                runSpacing: B2BSpacing.sm,
                children: [
                  for (final item in const [
                    ('all', 'All'),
                    ('esim', 'eSIM'),
                    ('physical_sim', 'SIM Card'),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: draftKind == item.$1,
                      onSelected: (_) => setSheetState(() => draftKind = item.$1),
                    ),
                ],
              ),
              if (_providers.isNotEmpty) ...[
                const SizedBox(height: B2BSpacing.lg),
                Text('Provider', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: B2BSpacing.sm),
                Wrap(
                  spacing: B2BSpacing.sm,
                  runSpacing: B2BSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: draftProvider == 'all',
                      onSelected: (_) => setSheetState(() => draftProvider = 'all'),
                    ),
                    for (final provider in _providers)
                      ChoiceChip(
                        label: Text(_providerLabel(provider)),
                        selected: draftProvider == provider,
                        onSelected: (_) => setSheetState(() => draftProvider = provider),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: B2BSpacing.xl),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _kind = draftKind;
                    _provider = draftProvider;
                  });
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Apply filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 2),
      body: SafeArea(
        child: RefreshIndicator(
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SIM & eSIM Inventory', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: B2BSpacing.xxs),
                        Text(
                          'Track activation, installation, usage and expiry.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search ICCID, customer or package',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Badge.count(
                    count: _activeFilterCount,
                    isLabelVisible: _activeFilterCount > 0,
                    child: IconButton.filledTonal(
                      onPressed: _openFilters,
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.md),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: B2BSpacing.xs),
                  itemBuilder: (context, index) => ChoiceChip(
                    label: Text(_tabs[index]),
                    selected: _selectedTab == index,
                    onSelected: (_) {
                      setState(() => _selectedTab = index);
                      _load();
                    },
                  ),
                ),
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (!_loading && _error == null && _esims.isNotEmpty) ...[
                _InventoryOverview(items: _esims),
                const SizedBox(height: B2BSpacing.lg),
              ],
              if (_loading)
                const ContentLoadingState(label: 'Loading inventory...')
              else if (_error != null)
                ContentErrorState(message: _error!, onRetry: _load)
              else if (visible.isEmpty)
                ContentEmptyState(
                  icon: Icons.sim_card_outlined,
                  title: 'No SIMs or eSIMs found',
                  message: 'Try another search, status or inventory filter.',
                  actionLabel: 'Clear filters',
                  onAction: () {
                    _searchController.clear();
                    setState(() {
                      _selectedTab = 0;
                      _kind = 'all';
                      _provider = 'all';
                    });
                    _load();
                  },
                )
              else
                for (var index = 0; index < visible.length; index++) ...[
                  _InventoryCard(
                    item: visible[index],
                    onTap: () => context.push('/esims/detail', extra: visible[index]),
                  ),
                  if (index != visible.length - 1)
                    const SizedBox(height: B2BSpacing.sm),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryOverview extends StatelessWidget {
  const _InventoryOverview({required this.items});

  final List<MobileEsim> items;

  @override
  Widget build(BuildContext context) {
    final active = items.where((item) => item.isActive).length;
    final pending = items.where((item) => item.isPending).length;
    final physical = items.where((item) => item.isPhysicalSim).length;
    return B2BSurface(
      backgroundColor: AppColors.navy,
      borderColor: AppColors.navy,
      child: Row(
        children: [
          Expanded(child: _OverviewValue(label: 'Total', value: '${items.length}')),
          Expanded(child: _OverviewValue(label: 'Active', value: '$active')),
          Expanded(child: _OverviewValue(label: 'Pending', value: '$pending')),
          Expanded(child: _OverviewValue(label: 'SIM Cards', value: '$physical')),
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: B2BSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      );
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onTap});

  final MobileEsim item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item);
    return B2BSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: Icon(
                  item.isPhysicalSim ? Icons.sim_card_rounded : Icons.qr_code_2_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: B2BSpacing.xxs),
                    Text(
                      '${item.provider} · ${item.isPhysicalSim ? 'SIM Card' : 'eSIM'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(B2BRadius.full),
                ),
                child: Text(
                  _statusLabel(item),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          _MetaRow(label: 'ICCID', value: item.iccid.isEmpty ? 'Pending' : item.iccid),
          if (item.customerName.isNotEmpty)
            _MetaRow(label: 'Customer', value: item.customerName),
          if (item.dataLabel.isNotEmpty || item.validityLabel.isNotEmpty)
            _MetaRow(
              label: 'Plan',
              value: [item.dataLabel, item.validityLabel].where((value) => value.isNotEmpty).join(' · '),
            ),
          if (item.expiresAt != null)
            _MetaRow(label: 'Expires', value: _formatDate(item.expiresAt)),
          if (item.usageRatio != null) ...[
            const SizedBox(height: B2BSpacing.sm),
            LinearProgressIndicator(value: item.usageRatio),
            const SizedBox(height: B2BSpacing.xs),
            Text('Data usage ${(item.usageRatio! * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: B2BSpacing.sm),
          Row(
            children: [
              Icon(
                item.hasQr ? Icons.qr_code_rounded : item.isPhysicalSim ? Icons.sim_card_outlined : Icons.hourglass_top_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: B2BSpacing.xs),
              Expanded(
                child: Text(
                  item.hasQr
                      ? 'Installation ready'
                      : item.isPhysicalSim
                          ? 'Physical SIM inventory'
                          : 'Provisioning',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: B2BSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

String _providerKey(String value) {
  final text = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (text.contains('worldmove') || text.contains('orangeeurope')) return 'worldmove';
  if (text.contains('tgt') || text.contains('orangebalkans')) return 'tgt';
  if (text.contains('airhub') || text.contains('vodafone')) return 'airhub';
  if (text.contains('flexnet') || text.contains('orangebigdata')) return 'flexnet';
  return text;
}

String _providerLabel(String provider) => switch (provider) {
      'worldmove' => 'Orange Europe',
      'tgt' => 'Orange Balkans',
      'airhub' => 'Vodafone',
      'flexnet' => 'Orange Big Data',
      _ => provider,
    };

String _statusLabel(MobileEsim item) {
  if (item.isExpired) return 'Expired';
  if (item.isActive) return 'Active';
  if (item.isPending) return 'Pending';
  final raw = item.status.trim();
  return raw.isEmpty ? 'Unknown' : raw;
}

Color _statusColor(MobileEsim item) {
  if (item.isExpired) return AppColors.danger;
  if (item.isActive) return AppColors.success;
  if (item.isPending) return AppColors.warning;
  return AppColors.primary;
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Not available';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
}
