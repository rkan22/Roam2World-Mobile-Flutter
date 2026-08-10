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
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.md,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            _Header(onBack: context.pop),
            const SizedBox(height: B2BSpacing.lg),
            const _SettingsHero(),
            const SizedBox(height: B2BSpacing.xl),
            const _SectionTitle('Workspace'),
            const SizedBox(height: B2BSpacing.sm),
            B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    title: 'App language',
                    subtitle: 'Language used across your B2B workspace',
                    trailing: language,
                    onTap: _selectLanguage,
                  ),
                  const Divider(height: 1),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.mode,
                    builder: (context, mode, child) => _SettingsTile(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Light, dark, or follow this device',
                      trailing: ThemeController.label(mode),
                      onTap: _selectTheme,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.xl),
            const _SectionTitle('Business notifications'),
            const SizedBox(height: B2BSpacing.sm),
            B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _PreferenceSwitch(
                    icon: Icons.receipt_long_outlined,
                    title: 'Order updates',
                    subtitle: 'Purchases, provisioning and delivery status',
                    value: orderNotifications,
                    onChanged: (value) =>
                        setState(() => orderNotifications = value),
                  ),
                  const Divider(height: 1),
                  _PreferenceSwitch(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet updates',
                    subtitle: 'Top-up requests and balance activity',
                    value: walletNotifications,
                    onChanged: (value) =>
                        setState(() => walletNotifications = value),
                  ),
                  const Divider(height: 1),
                  _PreferenceSwitch(
                    icon: Icons.campaign_outlined,
                    title: 'Product announcements',
                    subtitle: 'New destinations, packages and platform news',
                    value: productNotifications,
                    onChanged: (value) =>
                        setState(() => productNotifications = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.xl),
            const _SectionTitle('Security & platform'),
            const SizedBox(height: B2BSpacing.sm),
            const B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Secure token storage',
                    subtitle: 'Session credentials stay protected on device',
                    trailing: 'Active',
                    statusColor: AppColors.success,
                  ),
                  Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.https_outlined,
                    title: 'Production API security',
                    subtitle: 'Encrypted HTTPS API communication',
                    trailing: 'Protected',
                    statusColor: AppColors.success,
                  ),
                  Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.verified_user_outlined,
                    title: 'B2B role access',
                    subtitle: 'Workspace permissions follow your server role',
                    trailing: 'Server managed',
                    statusColor: AppColors.primary,
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
                RadioListTile<String>(value: item, title: Text(item)),
              const SizedBox(height: B2BSpacing.sm),
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
                const SizedBox(height: B2BSpacing.sm),
              ],
            ),
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
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: B2BSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: B2BSpacing.xxs),
              Text(
                'Control your Roam2World business workspace.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(B2BSpacing.xl),
      decoration: BoxDecoration(
        gradient: B2BGradients.primary,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        boxShadow: B2BShadows.hero,
      ),
      child: const Row(
        children: [
          _HeroIcon(),
          SizedBox(width: B2BSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace preferences',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: B2BSpacing.xs),
                Text(
                  'Keep notifications, appearance and business security aligned with your workflow.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(B2BRadius.md),
      ),
      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 27),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: B2BSpacing.md,
        vertical: B2BSpacing.xs,
      ),
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                trailing!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor ?? scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: B2BSpacing.md,
        vertical: B2BSpacing.xs,
      ),
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
