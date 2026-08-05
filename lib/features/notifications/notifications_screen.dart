import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Notifications'),
        actions: [TextButton(onPressed: () {}, child: const Text('Mark all read'))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: const [
          _SectionLabel('Today'),
          SizedBox(height: 10),
          _NotificationTile(icon: Icons.check_circle_rounded, color: AppColors.success, title: 'Order completed', message: 'Order #ORD-2026-000124 is ready. The eSIM QR code can now be shared.', time: '8 min ago', unread: true),
          SizedBox(height: 10),
          _NotificationTile(icon: Icons.account_balance_wallet_rounded, color: AppColors.primary, title: 'Wallet updated', message: 'Your top-up request for $1,000 has been approved.', time: '42 min ago', unread: true),
          SizedBox(height: 20),
          _SectionLabel('Earlier'),
          SizedBox(height: 10),
          _NotificationTile(icon: Icons.sim_card_rounded, color: AppColors.warning, title: 'Activation waiting', message: 'One purchased eSIM has not been installed yet.', time: 'Yesterday'),
          SizedBox(height: 10),
          _NotificationTile(icon: Icons.campaign_rounded, color: AppColors.primaryDark, title: 'New package available', message: 'A new Europe 20 GB package has been added to the catalogue.', time: '2 days ago'),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900));
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;
  final bool unread;
  const _NotificationTile({required this.icon, required this.color, required this.title, required this.message, required this.time, this.unread = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unread ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: unread ? AppColors.primary.withOpacity(.18) : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 46, width: 46, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))), if (unread) Container(height: 8, width: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))]),
                const SizedBox(height: 5),
                Text(message, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 8),
                Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
