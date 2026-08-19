import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  bool get _isReseller => widget.type == AdminPartnerType.resellers;
  String get _title => _isReseller ? 'Resellers' : 'Dealers';

  @override
  void initState() {
    super.initState();
    _search.addListener(_changed);
    _load();
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _search
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = _data == null; _error = null; });
    try {
      final data = _isReseller
          ? await _repository.fetchResellers()
          : await _repository.fetchDealers();
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = '$_title could not be loaded: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final query = _search.text.trim().toLowerCase();
    final visible = data?.items.where((item) {
      return query.isEmpty ||
          item.companyName.toLowerCase().contains(query) ||
          item.email.toLowerCase().contains(query);
    }).toList(growable: false) ?? const <AdminPartnerItem>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/operations'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Admin $_title'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, B2BSpacing.sm, B2BSpacing.lg, B2BSpacing.xxl),
          children: [
            Text('$_title workspace', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text('Live account directory from the backend.'),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && data == null)
              ContentLoadingState(label: 'Loading $_title...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Total', value: '${data.total}', icon: Icons.groups_2_outlined)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Active', value: '${data.active}', icon: Icons.verified_user_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.lg),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search ${_title.toLowerCase()} by name or email',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: _search.clear, icon: const Icon(Icons.close_rounded)),
                ),
              ),
              const SizedBox(height: B2BSpacing.md),
              if (visible.isEmpty)
                ContentEmptyState(icon: Icons.people_outline_rounded, title: 'No ${_title.toLowerCase()} found', message: query.isEmpty ? 'The backend returned no rows.' : 'No partner matches your search.')
              else
                for (final item in visible) ...[
                  _PartnerTile(item: item),
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
  const _PartnerTile({required this.item});
  final AdminPartnerItem item;

  @override
  Widget build(BuildContext context) {
    final status = item.isActive ? 'Active' : 'Suspended / Inactive';
    final statusColor = item.isActive ? Colors.green : Theme.of(context).colorScheme.outline;
    final last = item.lastActivity?.toLocal().toIso8601String().replaceFirst('T', ' ').split('.').first ?? 'No activity recorded';

    return B2BSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(child: Icon(Icons.business_rounded)),
            const SizedBox(width: B2BSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.companyName.isEmpty ? 'Reseller #${item.id}' : item.companyName, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (item.email.isNotEmpty) Text(item.email, style: Theme.of(context).textTheme.bodySmall),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: statusColor.withValues(alpha: .1), borderRadius: BorderRadius.circular(B2BRadius.pill)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: B2BSpacing.md),
          Wrap(spacing: B2BSpacing.lg, runSpacing: B2BSpacing.sm, children: [
            _Metric(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', value: '\$${item.walletBalance.toStringAsFixed(2)}'),
            _Metric(icon: Icons.people_outline, label: 'Customers', value: '${item.customerCount}'),
            _Metric(icon: Icons.shopping_bag_outlined, label: 'Orders', value: '${item.orderCount}'),
          ]),
          const SizedBox(height: B2BSpacing.sm),
          Text('Last activity: $last', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 17),
    const SizedBox(width: 5),
    Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
  ]);
}
