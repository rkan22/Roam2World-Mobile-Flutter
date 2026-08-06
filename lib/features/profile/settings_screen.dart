import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: context.pop,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account preferences',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Workspace'),
            const SizedBox(height: 12),
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
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.mode,
                    builder: (context, mode, child) => _SettingsTile(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Choose light, dark, or follow the device',
                      trailing: ThemeController.label(mode),
                      onTap: _selectTheme,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Notifications'),
            const SizedBox(height: 12),
            B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _PreferenceSwitch(
                    icon: Icons.receipt_long_outlined,
                    title: 'Order updates',
                    subtitle: 'Status and delivery events',
                    value: orderNotifications,
                    onChanged: (value) =>
                        setState(() => orderNotifications = value),
                  ),
                  const Divider(height: 1),
                  _PreferenceSwitch(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet updates',
                    subtitle: 'Top-up and balance activity',
                    value: walletNotifications,
                    onChanged: (value) =>
                        setState(() => walletNotifications = value),
                  ),
                  const Divider(height: 1),
                  _PreferenceSwitch(
                    icon: Icons.campaign_outlined,
                    title: 'Product announcements',
                    subtitle: 'New packages and platform news',
                    value: productNotifications,
                    onChanged: (value) =>
                        setState(() => productNotifications = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Security'),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  void _selectLanguage() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<String>(
          groupValue: language,
          onChanged: (value) {
            if (value == null) return;
            setState(() => language = value);
            Navigator.pop(sheetContext);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in const ['English', 'Türkçe', 'Deutsch'])
                RadioListTile<String>(
                  value: item,
                  title: Text(item),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTheme() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (context, selected, child) => RadioGroup<ThemeMode>(
            groupValue: selected,
            onChanged: (value) {
              if (value == null) return;
              ThemeController.setMode(value);
              Navigator.pop(sheetContext);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(ThemeController.label(mode)),
                    subtitle: Text(
                      mode == ThemeMode.system
                          ? 'Follow device appearance'
                          : 'Always use ${ThemeController.label(mode).toLowerCase()} mode',
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
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
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(B2BRadius.sm),
        ),
        child: Icon(icon, size: 21, color: scheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                color: statusColor ?? scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded),
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
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(B2BRadius.sm),
        ),
        child: Icon(icon, size: 21, color: scheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }
}
