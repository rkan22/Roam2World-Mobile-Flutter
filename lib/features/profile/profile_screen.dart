import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 4),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 20),
          _SettingsCard(
            children: [
              const _SettingsTile(icon: Icons.business_outlined, title: 'Company information'),
              _SettingsTile(icon: Icons.account_balance_wallet_outlined, title: 'Wallet', trailing: '\$12,450.00', onTap: () => context.push('/wallet')),
              _SettingsTile(icon: Icons.tune_rounded, title: 'App settings', trailing: 'English', onTap: () => context.push('/settings')),
              _SettingsTile(icon: Icons.notifications_none_rounded, title: 'Notifications', onTap: () => context.push('/notifications')),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            children: [
              _SettingsTile(icon: Icons.help_outline_rounded, title: 'Help & support', onTap: () => context.push('/support')),
              _SettingsTile(icon: Icons.shield_outlined, title: 'Security', onTap: () => context.push('/settings')),
              const _SettingsTile(icon: Icons.info_outline_rounded, title: 'About Roam2World', trailing: 'v1.0.0'),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primary, AppColors.navy])),
              child: const Text('EA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Erkan Aydoğan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Roam2World Business Account', style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(height: 6),
                Row(children: [Icon(Icons.verified_rounded, size: 16, color: AppColors.success), SizedBox(width: 5), Text('Verified reseller', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.success))]),
              ]),
            ),
            const Icon(Icons.edit_outlined, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Card(child: Column(children: children));
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 21, color: AppColors.primary)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (trailing != null) Text(trailing!, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ]),
    );
  }
}
