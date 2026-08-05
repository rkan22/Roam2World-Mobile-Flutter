import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String language = 'English';
  bool orderNotifications = true;
  bool walletNotifications = true;
  bool marketingNotifications = false;
  bool biometricLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const _SectionTitle('Language'),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: AppColors.primary),
              title: const Text('App language', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(language),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _selectLanguage,
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Notifications'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(value: orderNotifications, onChanged: (value) => setState(() => orderNotifications = value), title: const Text('Orders', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Status and delivery updates')),
                SwitchListTile(value: walletNotifications, onChanged: (value) => setState(() => walletNotifications = value), title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Top-up and balance updates')),
                SwitchListTile(value: marketingNotifications, onChanged: (value) => setState(() => marketingNotifications = value), title: const Text('Product news', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('New packages and announcements')),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Security'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(value: biometricLogin, onChanged: (value) => setState(() => biometricLogin = value), secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary), title: const Text('Biometric sign in', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Use Face ID or fingerprint')),
                const ListTile(leading: Icon(Icons.password_rounded, color: AppColors.primary), title: Text('Change password', style: TextStyle(fontWeight: FontWeight.w800)), trailing: Icon(Icons.chevron_right_rounded)),
                const ListTile(leading: Icon(Icons.devices_rounded, color: AppColors.primary), title: Text('Active sessions', style: TextStyle(fontWeight: FontWeight.w800)), trailing: Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectLanguage() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Türkçe', 'Deutsch'].map((item) => RadioListTile<String>(
            value: item,
            groupValue: language,
            title: Text(item),
            onChanged: (value) {
              if (value == null) return;
              setState(() => language = value);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900));
}
