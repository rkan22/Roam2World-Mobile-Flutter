import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 2),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Row(
                children: [
                  const Expanded(child: Text('eSIMs', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Track installation, activation and expiration.', style: TextStyle(color: AppColors.textSecondary)),
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

class _EsimCard extends StatelessWidget {
  const _EsimCard({required this.esim, required this.onTap});

  final MobileEsim esim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = esim.status.toLowerCase() == 'active' || esim.status.toLowerCase() == 'activated';
    final color = active ? AppColors.success : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.sim_card_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(esim.packageName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(esim.customerName.isEmpty ? esim.provider : esim.customerName, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(999)),
                  child: Text(esim.status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('ICCID', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Expanded(child: Text(esim.iccid.isEmpty ? 'Pending' : esim.iccid, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(esim.hasQr ? Icons.qr_code_rounded : Icons.hourglass_top_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(esim.hasQr ? 'Installation ready' : 'Provisioning', style: const TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
