import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_role.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'admin_support_data.dart';
import 'admin_support_repository.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final searchController = TextEditingController();
  final _tokenStorage = TokenStorage();
  final _adminRepository = AdminSupportRepository();

  bool _isAdmin = false;
  bool _adminLoading = false;
  String? _adminError;
  AdminSupportData? _adminData;
  Map<String, dynamic>? _systemHealth;

  static const _topics = <_SupportTopic>[
    _SupportTopic(Icons.qr_code_2_rounded, 'eSIM installation',
        'QR codes, manual setup and activation'),
    _SupportTopic(Icons.shopping_bag_outlined, 'Orders and delivery',
        'Order status, delivery and provisioning'),
    _SupportTopic(Icons.account_balance_wallet_outlined, 'Wallet and payments',
        'Top-ups, balances and transactions'),
    _SupportTopic(Icons.signal_cellular_alt_rounded, 'Coverage and usage',
        'Networks, roaming and data availability'),
    _SupportTopic(Icons.people_outline_rounded, 'Customers',
        'Customer assignments and B2B sales flow'),
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
    _loadAdminContext();
  }

  Future<void> _loadAdminContext() async {
    final profile = await _tokenStorage.readProfile();
    final role = parseAppRole((profile?['role'] ?? profile?['user_role'])?.toString());
    if (!mounted) return;
    setState(() => _isAdmin = role == AppRole.admin);
    if (role == AppRole.admin) {
      await _loadAdminData();
    }
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _adminLoading = true;
      _adminError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _adminRepository.fetchTickets(),
        _adminRepository.fetchSystemHealth(),
      ]);
      if (!mounted) return;
      setState(() {
        _adminData = results[0] as AdminSupportData;
        _systemHealth = Map<String, dynamic>.from(results[1] as Map);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _adminError = 'Admin support data could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _adminLoading = false);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<_SupportTopic> get _visibleTopics {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _topics;
    return _topics
        .where((topic) =>
            topic.title.toLowerCase().contains(query) ||
            topic.subtitle.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final topics = _visibleTopics;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _isAdmin ? _loadAdminData : () async {},
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
                  IconButton.filledTonal(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Support center',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: B2BSpacing.xxs),
                        Text('Help & Support',
                            style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ),
                  if (_isAdmin)
                    IconButton.filledTonal(
                      onPressed: _adminLoading ? null : _loadAdminData,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                ],
              ),
              const SizedBox(height: B2BSpacing.lg),
              Container(
                padding: const EdgeInsets.all(B2BSpacing.xl),
                decoration: BoxDecoration(
                  gradient: B2BGradients.primary,
                  borderRadius: BorderRadius.circular(B2BRadius.xl),
                  boxShadow: B2BShadows.hero,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.support_agent_rounded,
                        color: Colors.white, size: 34),
                    SizedBox(height: B2BSpacing.md),
                    Text(
                      'How can we help?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: B2BSpacing.xs),
                    Text(
                      'Find answers for eSIM provisioning, wallet operations, orders and your B2B workspace.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAdmin) ...[
                const SizedBox(height: B2BSpacing.xl),
                _buildAdminSection(),
              ],
              const SizedBox(height: B2BSpacing.lg),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search support topics',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: B2BSpacing.xl),
              Row(
                children: [
                  Text('Popular topics',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text('${topics.length} topics',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: B2BSpacing.sm),
              B2BSurface(
                padding: EdgeInsets.zero,
                child: topics.isEmpty
                    ? const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: B2BSpacing.xl),
                        child: Center(child: Text('No matching support topics')),
                      )
                    : Column(
                        children: [
                          for (var index = 0;
                              index < topics.length;
                              index++) ...[
                            _SupportTile(
                              topic: topics[index],
                              onTap: () => _showTopic(topics[index]),
                            ),
                            if (index != topics.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: B2BSpacing.xl),
              B2BSurface(
                showShadow: false,
                backgroundColor: AppColors.primaryLight,
                borderColor: AppColors.primarySoft,
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        color: AppColors.primary),
                    SizedBox(width: B2BSpacing.sm),
                    Expanded(
                      child: Text(
                        'For account-specific issues, include the order number, eSIM ICCID or wallet transaction reference when available.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminSection() {
    if (_adminLoading && _adminData == null) {
      return const B2BSurface(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: B2BSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_adminError != null && _adminData == null) {
      return B2BSurface(
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(child: Text(_adminError!)),
            TextButton(onPressed: _loadAdminData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final data = _adminData;
    if (data == null) return const SizedBox.shrink();

    final apiStatus = (_systemHealth?['api'] ?? 'unknown').toString();
    final databaseStatus = (_systemHealth?['database'] ?? 'unknown').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Admin support queue', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: B2BSpacing.sm),
        Row(
          children: [
            Expanded(child: _AdminStat(label: 'Open', value: data.openCount)),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(
                child: _AdminStat(
                    label: 'In progress', value: data.inProgressCount)),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(
                child: _AdminStat(label: 'Resolved', value: data.resolvedCount)),
          ],
        ),
        const SizedBox(height: B2BSpacing.sm),
        B2BSurface(
          child: Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  color: AppColors.primary),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Text(
                  'API: $apiStatus • Database: $databaseStatus',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: B2BSpacing.sm),
        B2BSurface(
          padding: EdgeInsets.zero,
          child: data.tickets.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(B2BSpacing.lg),
                  child: Text('No support tickets returned by the backend.'),
                )
              : Column(
                  children: [
                    for (var index = 0;
                        index < data.tickets.take(8).length;
                        index++) ...[
                      _AdminTicketTile(ticket: data.tickets[index]),
                      if (index != data.tickets.take(8).length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _showTopic(_SupportTopic topic) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            0,
            B2BSpacing.lg,
            B2BSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topic.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: B2BSpacing.xs),
              Text(topic.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: B2BSpacing.lg),
              const Text(
                'Ticket creation is not exposed by the verified mobile backend endpoint yet. Existing admin tickets are shown in the support queue above.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTopic {
  const _SupportTopic(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.topic, required this.onTap});

  final _SupportTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: B2BSpacing.md,
          vertical: B2BSpacing.xxs,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(B2BRadius.sm),
          ),
          child: Icon(topic.icon, color: AppColors.primary, size: 21),
        ),
        title: Text(topic.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(topic.subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

class _AdminStat extends StatelessWidget {
  const _AdminStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => B2BSurface(
        padding: const EdgeInsets.all(B2BSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _AdminTicketTile extends StatelessWidget {
  const _AdminTicketTile({required this.ticket});

  final AdminSupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final owner = ticket.clientName.isNotEmpty
        ? ticket.clientName
        : ticket.clientEmail.isNotEmpty
            ? ticket.clientEmail
            : 'Client';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: B2BSpacing.md,
        vertical: B2BSpacing.xxs,
      ),
      leading: const CircleAvatar(
        child: Icon(Icons.confirmation_number_outlined),
      ),
      title: Text(
        ticket.subject.isEmpty ? 'Support ticket #${ticket.id}' : ticket.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '$owner • ${ticket.status.isEmpty ? 'unknown' : ticket.status}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ticket.assignedToName.isEmpty
          ? null
          : Tooltip(
              message: 'Assigned to ${ticket.assignedToName}',
              child: const Icon(Icons.person_outline_rounded),
            ),
    );
  }
}
