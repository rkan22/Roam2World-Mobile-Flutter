import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String language = 'English';
  bool orderNotifications = true;
  bool walletNotifications = true;
  bool productNotifications = false;

  @override
  Widget build(BuildContext context) {
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
            _Header(onBack: context.pop),
            const SizedBox(height: B2BSpacing.lg),
            const _PreferenceNotice(),
            const SizedBox(height: B2BSpacing.xl),
            const _SectionTitle('Workspace'),
            const SizedBox(height: B2BSpacing.md),
            B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    title: 'App language',
                    subtitle: 'Language used in the mobile workspace',
                    trailing: language,
                    onTap: _selectLanguage,
                  ),
                  const Divider(height: 1),
                  const _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: 'Light theme is active for v1.0',
                    trailing: 'Light',
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.xl),
            const _SectionTitle('Notifications'),
            const SizedBox(height: B2BSpacing.md),
            B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _PreferenceSwitch(
                    icon: Icons.receipt_long_outlined,
                    title: 'Order updates',
                    subtitle: 'Status and delivery events',
                    value: orderNotifications,
                    onChanged: (value) {
                      setState(() => orderNotifications = value);
                    },
                  ),
                  const Divider(height: 1),
                  _PreferenceSwitch(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet updates',
                    subtitle: 'Top-up and balance activity',
                    value: walletNotifications,
                    onChanged: (value) {
                      setState(() => walletNotifications = value);
                    },
                  ),
                  const Divider(height: 1),
                  _PreferenceSwitch(
                    icon: Icons.campaign_outlined,
                    title: 'Product announcements',
                    subtitle: 'New packages and platform news',
                    value: productNotifications,
                    onChanged: (value) {
                      setState(() => productNotifications = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.xl),
            const _SectionTitle('Security'),
            const SizedBox(height: B2BSpacing.md),
            const B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Secure token storage',
                    subtitle: 'Session credentials are stored securely',
                    trailing: 'Active',
                    statusColor: AppColors.success,
                  ),
                  Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.https_outlined,
                    title: 'Production API security',
                    subtitle: 'HTTPS endpoint validation is enabled',
                    trailing: 'Protected',
                    statusColor: AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.xl),
            const _SectionTitle('About'),
            const SizedBox(height: B2BSpacing.md),
            const B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.business_center_outlined,
                    title: 'Roam2World B2B',
                    subtitle: 'Business eSIM management workspace',
                    trailing: 'v1.0.0',
                  ),
                  Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy & compliance',
                    subtitle: 'Store documentation required before release',
                    trailing: 'Pending',
                    statusColor: AppColors.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: B2BSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  B2BSpacing.lg,
                  B2BSpacing.xs,
                  B2BSpacing.lg,
                  B2BSpacing.md,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose language',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              for (final item in const ['English', 'Türkçe', 'Deutsch'])
                RadioListTile<String>(
                  value: item,
                  groupValue: language,
                  title: Text(item),
                  subtitle: item == 'English'
                      ? const Text('Current production language')
                      : const Text('Interface translation in progress'),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => language = value);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: B2BSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account preferences', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: B2BSpacing.xs),
              Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferenceNotice extends StatelessWidget {
  const _PreferenceNotice();

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      backgroundColor: AppColors.primaryLight,
      borderColor: AppColors.primary.withValues(alpha: .18),
      showShadow: false,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary),
          SizedBox(width: B2BSpacing.sm),
          Expanded(
            child: Text(
              'These preferences apply to the current app session. Persistent server-side preference sync will be enabled when supported by the backend.',
              style: TextStyle(fontWeight: FontWeight.w700, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.statusColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final trailingColor = statusColor ?? AppColors.textSecondary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: B2BSpacing.md,
        vertical: B2BSpacing.xs,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(B2BRadius.sm),
        ),
        child: Icon(icon, size: 21, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(color: trailingColor, fontWeight: FontWeight.w800),
            ),
          if (onTap != null) ...[
            const SizedBox(width: B2BSpacing.xs),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: B2BSpacing.md,
        vertical: B2BSpacing.xs,
      ),
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(B2BRadius.sm),
        ),
        child: Icon(icon, size: 21, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }
}
