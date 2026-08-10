import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final searchController = TextEditingController();

  static const _topics = <_SupportTopic>[
    _SupportTopic(Icons.qr_code_2_rounded, 'eSIM installation', 'QR codes, manual setup and activation'),
    _SupportTopic(Icons.shopping_bag_outlined, 'Orders and delivery', 'Order status, delivery and provisioning'),
    _SupportTopic(Icons.account_balance_wallet_outlined, 'Wallet and payments', 'Top-ups, balances and transactions'),
    _SupportTopic(Icons.signal_cellular_alt_rounded, 'Coverage and usage', 'Networks, roaming and data availability'),
    _SupportTopic(Icons.people_outline_rounded, 'Customers', 'Customer assignments and B2B sales flow'),
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
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
        child: ListView(
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
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Support center', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: B2BSpacing.xxs),
                      Text('Help & Support', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(B2BRadius.md),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: B2BSpacing.lg),
                  const Text(
                    'How can we help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: B2BSpacing.xs),
                  const Text(
                    'Find answers for eSIM provisioning, wallet operations, orders and your B2B workspace.',
                    style: TextStyle(color: Colors.white70, height: 1.45, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
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
                Text('Popular topics', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text('${topics.length} topics', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: B2BSpacing.sm),
            if (topics.isEmpty)
              B2BSurface(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: B2BSpacing.xl),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 38, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: B2BSpacing.sm),
                      const Text('No matching support topics', style: TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              )
            else
              B2BSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < topics.length; index++) ...[
                      _SupportTile(topic: topics[index], onTap: () => _showTopic(topics[index])),
                      if (index != topics.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: B2BSpacing.xl),
            Text('Contact support', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: B2BSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ContactCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Live chat',
                    subtitle: 'Fast assistance',
                    onTap: () => _showMessage('Live chat integration can be connected to your support service.'),
                  ),
                ),
                const SizedBox(width: B2BSpacing.sm),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Create ticket',
                    subtitle: 'Detailed request',
                    onTap: _showTicketSheet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: B2BSpacing.lg),
            B2BSurface(
              showShadow: false,
              backgroundColor: AppColors.primaryLight,
              borderColor: AppColors.primarySoft,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: Text(
                      'For account-specific issues, include the order number, eSIM ICCID or wallet transaction reference when available.',
                      style: TextStyle(fontWeight: FontWeight.w700, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopic(_SupportTopic topic) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(B2BSpacing.lg, 0, B2BSpacing.lg, B2BSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: Icon(topic.icon, color: AppColors.primary),
              ),
              const SizedBox(height: B2BSpacing.md),
              Text(topic.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: B2BSpacing.xs),
              Text(topic.subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: B2BSpacing.lg),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _showTicketSheet();
                },
                child: const Text('Ask support about this'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketSheet() {
    final subjectController = TextEditingController();
    final detailController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          B2BSpacing.lg,
          B2BSpacing.xxs,
          B2BSpacing.lg,
          MediaQuery.viewInsetsOf(sheetContext).bottom + B2BSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create support ticket', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            Text('Describe the B2B issue and include any relevant order or eSIM reference.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: B2BSpacing.lg),
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
            const SizedBox(height: B2BSpacing.sm),
            TextField(controller: detailController, maxLines: 4, decoration: const InputDecoration(labelText: 'Describe the issue')),
            const SizedBox(height: B2BSpacing.lg),
            FilledButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                _showMessage('Ticket UI is ready; connect this action to the production support endpoint.');
              },
              child: const Text('Submit ticket'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      subjectController.dispose();
      detailController.dispose();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        contentPadding: const EdgeInsets.symmetric(horizontal: B2BSpacing.md, vertical: B2BSpacing.xxs),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(B2BRadius.sm),
          ),
          child: Icon(topic.icon, color: AppColors.primary, size: 21),
        ),
        title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(topic.subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => B2BSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(B2BSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(B2BRadius.sm),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: B2BSpacing.md),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}
