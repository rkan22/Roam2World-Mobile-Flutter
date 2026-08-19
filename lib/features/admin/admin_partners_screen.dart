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
  AdminPartnerList? _data;
  bool _loading = true;
  String? _error;
  bool get _isReseller => widget.type == AdminPartnerType.resellers;
  String get _title => _isReseller ? 'Resellers' : 'Dealers';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = _data == null; _error = null; });
    try {
      final data = _isReseller ? await _repository.fetchResellers() : await _repository.fetchDealers();
      if (mounted) setState(() => _data = data);
    } catch (error) { if (mounted) setState(() => _error = '$_title could not be loaded: $error'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    final data = _data;
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
              _PartnerSearchField(title: _title, items: data.items, onDetail: _openDetail),
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
    if (mounted) await _load();
  }
}

class _PartnerSearchField extends StatefulWidget {
  const _PartnerSearchField({required this.title, required this.items, required this.onDetail});
  final String title;
  final List<AdminPartnerItem> items;
  final Future<void> Function(int id) onDetail;
  @override State<_PartnerSearchField> createState() => _PartnerSearchFieldState();
}

class _PartnerSearchFieldState extends State<_PartnerSearchField> {
  late final TextEditingController _controller;
  @override void initState() { super.initState(); _controller = TextEditingController(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final visible = widget.items.where((item) => query.isEmpty || item.companyName.toLowerCase().contains(query) || item.email.toLowerCase().contains(query) || item.resellerName.toLowerCase().contains(query)).toList(growable: false);
    return Column(children: [
      TextField(controller: _controller, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'Search ${widget.title.toLowerCase()} by name, email or reseller', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _controller.text.isEmpty ? null : IconButton(onPressed: _controller.clear, icon: const Icon(Icons.close_rounded)))),
      const SizedBox(height: B2BSpacing.md),
      if (visible.isEmpty) ContentEmptyState(icon: Icons.people_outline_rounded, title: 'No ${widget.title.toLowerCase()} found', message: query.isEmpty ? 'The backend returned no rows.' : 'No partner matches your search.')
      else for (final item in visible) ...[
        _PartnerTile(item: item, onDetail: () => widget.onDetail(item.id)),
        const SizedBox(height: B2BSpacing.sm),
      ],
    ]);
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
      Text(item.companyName, style: Theme.of(context).textTheme.titleLarge),
      Text(item.email),
      Text('Reseller: ${item.resellerName.isEmpty ? '—' : item.resellerName}'),
      Text('Wallet: \$${item.walletBalance.toStringAsFixed(2)}'),
      Text('Customers: ${item.customerCount} • Orders: ${item.orderCount}'),
      Text('Status: $status • Last activity: $last'),
      const SizedBox(height: B2BSpacing.sm),
      Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: onDetail, icon: const Icon(Icons.open_in_new_rounded), label: const Text('Details'))),
    ]));
  }
}

class _ResellerDetailSheet extends StatefulWidget {
  const _ResellerDetailSheet({required this.repository, required this.resellerId});
  final AdminPartnersRepository repository;
  final int resellerId;
  @override State<_ResellerDetailSheet> createState() => _ResellerDetailSheetState();
}

class _ResellerDetailSheetState extends State<_ResellerDetailSheet> {
  AdminResellerDetail? _detail;
  bool _saving = false;
  late final TextEditingController _first = TextEditingController();
  late final TextEditingController _last = TextEditingController();
  late final TextEditingController _email = TextEditingController();
  late final TextEditingController _country = TextEditingController();
  late final TextEditingController _phone = TextEditingController();
  late final TextEditingController _clients = TextEditingController();
  late final TextEditingController _sims = TextEditingController();
  late final TextEditingController _credit = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final d = await widget.repository.fetchResellerDetail(widget.resellerId);
    if (!mounted) return;
    setState(() {
      _detail = d;
      _first.text = d.firstName;
      _last.text = d.lastName;
      _email.text = d.email;
      _country.text = d.phoneCountryCode;
      _phone.text = d.phoneNumber;
      _clients.text = '${d.maxClients}';
      _sims.text = '${d.maxSims}';
      _credit.text = '${d.creditLimit}';
    });
  }

  Future<void> _save() async {
    if (_detail == null) return;
    setState(() => _saving = true);
    try {
      await widget.repository.updateReseller(widget.resellerId, {
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'email': _email.text.trim(),
        'country_code': _country.text.trim(),
        'phone_number': _phone.text.trim(),
        'max_clients': int.tryParse(_clients.text),
        'max_sims': int.tryParse(_sims.text),
        'credit_limit': double.tryParse(_credit.text),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _country.dispose();
    _phone.dispose();
    _clients.dispose();
    _sims.dispose();
    _credit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail == null
                ? const CircularProgressIndicator()
                : Text(
                    'Reseller • ${_detail!.email}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
            if (_detail != null) ...[
              Text('Status: ${_detail!.status}'),
              Text('Wallet: \$${_detail!.currentCredit.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              _field('First name', _first),
              _field('Last name', _last),
              _field('Email', _email, keyboard: TextInputType.emailAddress),
              _field('Country code', _country),
              _field('Phone', _phone, keyboard: TextInputType.phone),
              _field('Max clients', _clients, keyboard: TextInputType.number),
              _field('Max SIMs', _sims, keyboard: TextInputType.number),
              _field(
                'Credit limit',
                _credit,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save changes'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DealerDetailSheet extends StatefulWidget {
  const _DealerDetailSheet({required this.repository, required this.dealerId});
  final AdminPartnersRepository repository;
  final int dealerId;
  @override State<_DealerDetailSheet> createState() => _DealerDetailSheetState();
}

class _DealerDetailSheetState extends State<_DealerDetailSheet> {
  AdminDealerDetail? _detail;
  bool _saving = false;
  late final TextEditingController _first = TextEditingController();
  late final TextEditingController _last = TextEditingController();
  late final TextEditingController _email = TextEditingController();
  late final TextEditingController _country = TextEditingController();
  late final TextEditingController _phone = TextEditingController();
  late final TextEditingController _clients = TextEditingController();
  late final TextEditingController _sims = TextEditingController();
  late final TextEditingController _credit = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final d = await widget.repository.fetchDealerDetail(widget.dealerId);
    if (!mounted) return;
    setState(() {
      _detail = d;
      _first.text = d.firstName;
      _last.text = d.lastName;
      _email.text = d.email;
      _country.text = '';
      _phone.text = '';
      _clients.text = '${d.totalClients}';
      _sims.text = '';
      _credit.text = '${d.currentBalance}';
    });
  }

  Future<void> _save() async {
    if (_detail == null) return;
    setState(() => _saving = true);
    try {
      await widget.repository.updateDealer(widget.dealerId, {
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'email': _email.text.trim(),
        'max_clients': int.tryParse(_clients.text),
        'credit_limit': double.tryParse(_credit.text),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _country.dispose();
    _phone.dispose();
    _clients.dispose();
    _sims.dispose();
    _credit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail == null
                ? const CircularProgressIndicator()
                : Text(
                    'Dealer • ${_detail!.email}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
            if (_detail != null) ...[
              Text(
                'Status: ${_detail!.isSuspended
                    ? 'Suspended'
                    : (_detail!.isActive ? 'Active' : 'Inactive')}',
              ),
              Text('Wallet: \$${_detail!.currentBalance.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              _field('First name', _first),
              _field('Last name', _last),
              _field('Email', _email, keyboard: TextInputType.emailAddress),
              _field('Max clients', _clients, keyboard: TextInputType.number),
              _field(
                'Credit limit',
                _credit,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save changes'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _field(String label, TextEditingController controller, {TextInputType? keyboard}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
    );
