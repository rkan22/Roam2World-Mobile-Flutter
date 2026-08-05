import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.navy]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent_rounded, size: 38, color: Colors.white),
                SizedBox(height: 16),
                Text('How can we help?', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Find answers or contact the Roam2World support team.', style: TextStyle(color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(controller: searchController, decoration: const InputDecoration(hintText: 'Search help articles', prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 22),
          const Text('Popular topics', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Card(
            child: Column(
              children: [
                _SupportTile(icon: Icons.qr_code_2_rounded, title: 'eSIM installation', subtitle: 'QR codes, manual setup and activation'),
                _SupportTile(icon: Icons.shopping_bag_outlined, title: 'Orders and delivery', subtitle: 'Order status, resend and cancellation'),
                _SupportTile(icon: Icons.account_balance_wallet_outlined, title: 'Wallet and payments', subtitle: 'Top-ups, invoices and transactions'),
                _SupportTile(icon: Icons.signal_cellular_alt_rounded, title: 'Coverage and usage', subtitle: 'Networks, roaming and data balance'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Contact us', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ContactCard(icon: Icons.chat_bubble_outline_rounded, label: 'Live chat', onTap: () => _showMessage('Live chat will connect to the support service.'))),
              const SizedBox(width: 12),
              Expanded(child: _ContactCard(icon: Icons.confirmation_number_outlined, label: 'Create ticket', onTap: _showTicketSheet)),
            ],
          ),
        ],
      ),
    );
  }

  void _showTicketSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Create support ticket', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Subject')),
            const SizedBox(height: 12),
            const TextField(maxLines: 4, decoration: InputDecoration(labelText: 'Describe the issue')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { Navigator.pop(context); _showMessage('Support ticket created.'); }, child: const Text('Submit Ticket')),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SupportTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppColors.primary)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 106,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppColors.primary), const SizedBox(height: 9), Text(label, style: const TextStyle(fontWeight: FontWeight.w900))]),
        ),
      );
}
