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
  @override State<AdminPartnersScreen> createState() => _AdminPartnersScreenState();
}

class _AdminPartnersScreenState extends State<AdminPartnersScreen> {
  final _repository = AdminPartnersRepository();
  final _search = TextEditingController();
  AdminPartnerList? _data;
  bool _loading = true;
  String? _error;
  bool get _isReseller => widget.type == AdminPartnerType.resellers;
  String get _title => _isReseller ? 'Resellers' : 'Dealers';

  @override void initState() { super.initState(); _search.addListener(_changed); _load(); }
  void _changed() => setState(() {});
  @override void dispose() { _search..removeListener(_changed)..dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = _data == null; _error = null; });
    try {
      final data = _isReseller ? await _repository.fetchResellers() : await _repository.fetchDealers();
      if (mounted) setState(() => _data = data);
    } catch (error) { if (mounted) setState(() => _error = '$_title could not be loaded: $error'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    final data = _data;
    final query = _search.text.trim().toLowerCase();
    final visible = data?.items.where((item) => query.isEmpty || item.companyName.toLowerCase().contains(query) || item.email.toLowerCase().contains(query) || item.resellerName.toLowerCase().contains(query)).toList(growable: false) ?? const <AdminPartnerItem>[];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.canPop() ? context.pop() : context.go('/operations'), icon: const Icon(Icons.arrow_back_rounded)),
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
            if (_loading && data == null) ContentLoadingState(label: 'Loading $_title...')
            else if (_error != null && data == null) ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              Row(children: [
                Expanded(child: B2BMetricCard(label: 'Total', value: '${data.total}', icon: Icons.groups_2_outlined)),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(child: B2BMetricCard(label: 'Active', value: '${data.active}', icon: Icons.verified_user_outlined)),
              ]),
              const SizedBox(height: B2BSpacing.lg),
              TextField(controller: _search, decoration: InputDecoration(hintText: 'Search ${_title.toLowerCase()} by name, email or reseller', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: _search.clear, icon: const Icon(Icons.close_rounded)))),
              const SizedBox(height: B2BSpacing.md),
              if (visible.isEmpty) ContentEmptyState(icon: Icons.people_outline_rounded, title: 'No ${_title.toLowerCase()} found', message: query.isEmpty ? 'The backend returned no rows.' : 'No partner matches your search.')
              else for (final item in visible) ...[
                _PartnerTile(item: item, onDetail: () => _openDetail(item.id)),
                const SizedBox(height: B2BSpacing.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(int id) async {
    if (_isReseller) {
      await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _ResellerDetailSheet(repository: _repository, resellerId: id));
    } else {
      await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _DealerDetailSheet(repository: _repository, dealerId: id));
    }
    await _load();
  }
}

class _PartnerTile extends StatelessWidget {
  const _PartnerTile({required this.item, required this.onDetail});
  final AdminPartnerItem item;
  final VoidCallback onDetail;
  @override Widget build(BuildContext context) {
    final status = item.isSuspended ? 'Suspended' : (item.isActive ? 'Active' : 'Inactive');
    final last = item.lastActivity?.toLocal().toIso8601String().replaceFirst('T', ' ').split('.').first ?? 'No activity recorded';
    return B2BSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const CircleAvatar(child: Icon(Icons.business_rounded)), const SizedBox(width: B2BSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.companyName.isEmpty ? 'Partner #${item.id}' : item.companyName, style: const TextStyle(fontWeight: FontWeight.w900)), if (item.email.isNotEmpty) Text(item.email, style: Theme.of(context).textTheme.bodySmall), if (item.resellerName.isNotEmpty) Text('Reseller: ${item.resellerName}', style: Theme.of(context).textTheme.bodySmall)])),
        Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: item.isActive ? Colors.green : Theme.of(context).colorScheme.outline)),
      ]),
      const SizedBox(height: B2BSpacing.md),
      Wrap(spacing: B2BSpacing.lg, runSpacing: B2BSpacing.sm, children: [
        _Metric(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', value: '\$${item.walletBalance.toStringAsFixed(2)}'),
        _Metric(icon: Icons.people_outline, label: 'Customers', value: '${item.customerCount}'),
        _Metric(icon: Icons.shopping_bag_outlined, label: 'Orders', value: '${item.orderCount}'),
      ]),
      const SizedBox(height: B2BSpacing.sm),
      Row(children: [Expanded(child: Text('Last activity: $last', style: Theme.of(context).textTheme.bodySmall)), TextButton.icon(onPressed: onDetail, icon: const Icon(Icons.manage_accounts_outlined), label: const Text('Details'))]),
    ]));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 17), const SizedBox(width: 5), Text('$label: ', style: Theme.of(context).textTheme.bodySmall), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]);
}

class _DealerDetailSheet extends StatefulWidget {
  const _DealerDetailSheet({required this.repository, required this.dealerId});
  final AdminPartnersRepository repository; final int dealerId;
  @override State<_DealerDetailSheet> createState() => _DealerDetailSheetState();
}
class _DealerDetailSheetState extends State<_DealerDetailSheet> {
  AdminDealerDetail? _detail; bool _loading = true; bool _saving = false;
  late final TextEditingController _first = TextEditingController(); late final TextEditingController _last = TextEditingController(); late final TextEditingController _email = TextEditingController(); late final TextEditingController _country = TextEditingController(); late final TextEditingController _phone = TextEditingController(); late final TextEditingController _notes = TextEditingController();
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _first.dispose(); _last.dispose(); _email.dispose(); _country.dispose(); _phone.dispose(); _notes.dispose(); super.dispose(); }
  Future<void> _load() async { try { final d = await widget.repository.fetchDealerDetail(widget.dealerId); if (!mounted) return; setState(() { _detail = d; _first.text = d.firstName; _last.text = d.lastName; _email.text = d.email; }); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load dealer: $e'))); } finally { if (mounted) setState(() => _loading = false); } }
  Future<void> _save() async { setState(() => _saving = true); try { final d = await widget.repository.updateDealer(widget.dealerId, {'first_name': _first.text.trim(), 'last_name': _last.text.trim(), 'email': _email.text.trim(), 'country_code': _country.text.trim(), 'phone_number': _phone.text.trim(), 'notes': _notes.text.trim()}); if (mounted) { setState(() => _detail = d); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dealer account updated'))); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'))); } finally { if (mounted) setState(() => _saving = false); } }
  Future<void> _toggleStatus() async { final suspended = !(_detail?.isSuspended ?? false); setState(() => _saving = true); try { final d = await widget.repository.setDealerStatus(widget.dealerId, suspend: suspended, reason: suspended ? 'Suspended by admin' : ''); if (mounted) setState(() => _detail = d); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status update failed: $e'))); } finally { if (mounted) setState(() => _saving = false); } }
  @override Widget build(BuildContext context) => DraggableScrollableSheet(expand: false, initialChildSize: .9, builder: (_, controller) => Material(child: _loading ? const Center(child: CircularProgressIndicator()) : _detail == null ? const Center(child: Text('Dealer not found')) : ListView(controller: controller, padding: const EdgeInsets.all(20), children: [Row(children: [Expanded(child: Text('Dealer account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]), Text('Reseller: ${_detail!.resellerName.isEmpty ? 'Not assigned' : _detail!.resellerName}'), Text('Wallet: \$${_detail!.currentBalance.toStringAsFixed(2)}'), Text('Customers: ${_detail!.totalClients}   Orders: ${_detail!.totalOrders}'), const SizedBox(height: 16), _field('First name', _first), _field('Last name', _last), _field('Email', _email, keyboard: TextInputType.emailAddress), _field('Country code', _country), _field('Phone', _phone, keyboard: TextInputType.phone), _field('Notes', _notes, maxLines: 3), const SizedBox(height: 12), FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save changes')), const SizedBox(height: 8), OutlinedButton.icon(onPressed: _saving ? null : _toggleStatus, icon: Icon(_detail!.isSuspended ? Icons.play_arrow_rounded : Icons.pause_rounded), label: Text(_detail!.isSuspended ? 'Activate dealer' : 'Suspend dealer'))])));
  Widget _field(String label, TextEditingController c, {TextInputType? keyboard, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: c, keyboardType: keyboard, maxLines: maxLines, decoration: InputDecoration(labelText: label)));
}

class _ResellerDetailSheet extends StatefulWidget {
  const _ResellerDetailSheet({required this.repository, required this.resellerId});
  final AdminPartnersRepository repository; final int resellerId;
  @override State<_ResellerDetailSheet> createState() => _ResellerDetailSheetState();
}
class _ResellerDetailSheetState extends State<_ResellerDetailSheet> {
  AdminResellerDetail? _detail; bool _loading = true; bool _saving = false;
  late final TextEditingController _first = TextEditingController(); late final TextEditingController _last = TextEditingController(); late final TextEditingController _email = TextEditingController(); late final TextEditingController _country = TextEditingController(); late final TextEditingController _phone = TextEditingController(); late final TextEditingController _clients = TextEditingController(); late final TextEditingController _sims = TextEditingController(); late final TextEditingController _credit = TextEditingController();
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _first.dispose(); _last.dispose(); _email.dispose(); _country.dispose(); _phone.dispose(); _clients.dispose(); _sims.dispose(); _credit.dispose(); super.dispose(); }
  Future<void> _load() async { try { final d = await widget.repository.fetchResellerDetail(widget.resellerId); if (!mounted) return; setState(() { _detail = d; _first.text = d.firstName; _last.text = d.lastName; _email.text = d.email; _country.text = d.phoneCountryCode; _phone.text = d.phoneNumber; _clients.text = '${d.maxClients}'; _sims.text = '${d.maxSims}'; _credit.text = d.creditLimit.toStringAsFixed(2); }); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load reseller: $e'))); } finally { if (mounted) setState(() => _loading = false); } }
  Future<void> _save() async { setState(() => _saving = true); try { final d = await widget.repository.updateReseller(widget.resellerId, {'email': _email.text.trim(), 'first_name': _first.text.trim(), 'last_name': _last.text.trim(), 'country_code': _country.text.trim(), 'phone_number': _phone.text.trim(), 'max_clients': int.tryParse(_clients.text) ?? 0, 'max_sims': int.tryParse(_sims.text) ?? 0, 'credit_limit': double.tryParse(_credit.text) ?? 0}); if (mounted) { setState(() => _detail = d); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reseller account updated'))); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'))); } finally { if (mounted) setState(() => _saving = false); } }
  @override Widget build(BuildContext context) => DraggableScrollableSheet(expand: false, initialChildSize: .9, builder: (_, controller) => Material(child: _loading ? const Center(child: CircularProgressIndicator()) : _detail == null ? const Center(child: Text('Reseller not found')) : ListView(controller: controller, padding: const EdgeInsets.all(20), children: [Row(children: [Expanded(child: Text('Reseller account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]), Text('Status: ${_detail!.status}'), Text('Wallet: \$${_detail!.currentCredit.toStringAsFixed(2)}'), const SizedBox(height: 16), _field('First name', _first), _field('Last name', _last), _field('Email', _email, keyboard: TextInputType.emailAddress), _field('Country code', _country), _field('Phone', _phone, keyboard: TextInputType.phone), _field('Max clients', _clients, keyboard: TextInputType.number), _field('Max SIMs', _sims, keyboard: TextInputType.number), _field('Credit limit', _credit, keyboard: const TextInputType.numberWithOptions(decimal: true)), const SizedBox(height: 12), FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save changes'))])));
  Widget _field(String label, TextEditingController c, {TextInputType? keyboard}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(labelText: label)));
}
