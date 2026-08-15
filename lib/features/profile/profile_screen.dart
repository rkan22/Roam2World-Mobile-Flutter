import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/routing/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../shared/widgets/r2w_bottom_nav.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_session.dart';
import '../dashboard/dashboard_data.dart';
import '../dashboard/dashboard_repository.dart';
import 'profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepository = AuthRepository();
  final _profileRepository = ProfileRepository();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  AuthSession? _session;
  MobileUserProfile? _profile;
  DashboardData? _dashboard;
  bool _loading = true;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final session = await _authRepository.readStoredProfile();
    MobileUserProfile? profile;
    DashboardData? dashboard;
    try {
      profile = await _profileRepository.fetchProfile();
    } catch (_) {}
    final role = parseAppRole(profile?.role ?? session?.role);
    if (role == AppRole.dealer) {
      try {
        dashboard = await DashboardRepository(role: role).fetchDashboard();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _profile = profile;
      _dashboard = dashboard;
      _loading = false;
    });
  }

  String _profileValue(String key) =>
      (_profile?.profile[key] ?? '').toString().trim();

  String get _fullName {
    final value = _profile?.fullName.trim() ?? '';
    if (value.isNotEmpty) return value;
    final stored = _session?.displayName?.trim() ?? '';
    return stored.isNotEmpty ? stored : 'Dealer account';
  }

  String get _email {
    final value = _profile?.email.trim() ?? '';
    return value.isNotEmpty ? value : (_session?.email ?? '');
  }

  String get _phone {
    final number = _profile?.phoneNumber.trim() ?? '';
    final code = _profile?.countryCode.trim() ?? '';
    if (number.isEmpty) return 'Not provided';
    return '$code $number'.trim();
  }

  Future<void> _editProfile() async {
    final first = TextEditingController(text: _profile?.firstName ?? '');
    final last = TextEditingController(text: _profile?.lastName ?? '');
    final countryCode = TextEditingController(text: _profile?.countryCode ?? '');
    final phone = TextEditingController(text: _profile?.phoneNumber ?? '');
    final country = TextEditingController(text: _profileValue('country'));
    final city = TextEditingController(text: _profileValue('city'));
    final postal = TextEditingController(text: _profileValue('postal_code'));
    final address = TextEditingController(text: _profileValue('address'));

    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit profile', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: first, decoration: const InputDecoration(labelText: 'First name'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: last, decoration: const InputDecoration(labelText: 'Last name'))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                SizedBox(width: 100, child: TextField(controller: countryCode, decoration: const InputDecoration(labelText: 'Code'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone'))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: country, decoration: const InputDecoration(labelText: 'Country')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: city, decoration: const InputDecoration(labelText: 'City'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: postal, decoration: const InputDecoration(labelText: 'Postal code'))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (save != true || !mounted) return;
    try {
      await _profileRepository.updateProfile(
        firstName: first.text,
        lastName: last.text,
        countryCode: countryCode.text,
        phoneNumber: phone.text,
        country: country.text,
        city: city.text,
        postalCode: postal.text,
        address: address.text,
      );
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile could not be updated: $error')));
    }
  }

  Future<void> _changePassword() async {
    if (_oldPassword.text.isEmpty || _newPassword.text.length < 8 || _newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your current password and make sure the new passwords match (minimum 8 characters).')));
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await _profileRepository.changePassword(
        oldPassword: _oldPassword.text,
        newPassword: _newPassword.text,
        confirmPassword: _confirmPassword.text,
      );
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password could not be changed: $error')));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Your secure business session will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _authRepository.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDealer = parseAppRole(_profile?.role ?? _session?.role) == AppRole.dealer;
    return Scaffold(
      bottomNavigationBar: const R2WBottomNav(selectedIndex: 4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Profile Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(isDealer ? 'Manage your dealer account and preferences.' : 'Manage your account and preferences.', style: Theme.of(context).textTheme.bodySmall),
                ])),
                OutlinedButton.icon(onPressed: _loading ? null : _editProfile, icon: const Icon(Icons.edit_outlined, size: 17), label: const Text('Edit Profile')),
              ]),
              const SizedBox(height: 18),
              _section('Personal Information', _personalInformation()),
              const SizedBox(height: 18),
              _section('Account Status', _accountStatus()),
              if (isDealer && _dashboard != null) ...[
                const SizedBox(height: 18),
                Text('Quick Stats', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                _quickStats(),
              ],
              const SizedBox(height: 18),
              _section('Change Password', _passwordForm()),
              const SizedBox(height: 18),
              _section('Theme Settings', _themeSettings()),
              const SizedBox(height: 18),
              _logoutCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          B2BSurface(padding: const EdgeInsets.all(16), child: child),
        ],
      );

  Widget _personalInformation() => Column(children: [
        _info('Full Name', _fullName),
        _info('Email', _email.isEmpty ? 'Not provided' : _email),
        _info('Phone Number', _phone),
        _info('Country', _profileValue('country').isEmpty ? 'Not provided' : _profileValue('country')),
        _info('City', _profileValue('city').isEmpty ? 'Not provided' : _profileValue('city')),
        _info('Postal Code', _profileValue('postal_code').isEmpty ? 'Not provided' : _profileValue('postal_code')),
        _info('Address', _profileValue('address').isEmpty ? 'Not provided' : _profileValue('address'), last: true),
      ]);

  Widget _accountStatus() {
    final created = _profile?.createdAt;
    final login = _profile?.lastLogin;
    return Column(children: [
      _info('Status', _profile?.isActive == false ? 'Inactive' : 'Active', valueColor: _profile?.isActive == false ? AppColors.danger : AppColors.success),
      _info('Account Type', _roleLabel(_profile?.role ?? _session?.role)),
      if (created != null) _info('Member Since', DateFormat('MMM d, yyyy').format(created.toLocal())),
      if (login != null) _info('Last Login', DateFormat('MMM d, yyyy, HH:mm').format(login.toLocal()), last: true),
    ]);
  }

  Widget _quickStats() {
    final data = _dashboard!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _stat('Total eSIMs', '${data.totalEsimCount}', Icons.sim_card_outlined, const Color(0xFF334155), const Color(0xFFF1F5F9)),
        _stat('Active eSIMs', '${data.activeEsimCount}', Icons.check_circle_outline_rounded, AppColors.success, AppColors.successSoft),
        _stat('Total Orders', '${data.totalOrders}', Icons.receipt_long_outlined, AppColors.violet, const Color(0xFFF3EEFF)),
        _stat('Sales (${data.period})', _money(data.monthlySales, data.currency), Icons.payments_outlined, AppColors.orange, const Color(0xFFFFF2E8)),
      ],
    );
  }

  Widget _passwordForm() => Column(children: [
        TextField(controller: _oldPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
        const SizedBox(height: 12),
        TextField(controller: _newPassword, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', helperText: 'Minimum 8 characters')),
        const SizedBox(height: 12),
        TextField(controller: _confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: _savingPassword ? null : _changePassword, child: Text(_savingPassword ? 'Changing...' : 'Change Password'))),
      ]);

  Widget _themeSettings() => ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.mode,
        builder: (context, selected, child) => Row(children: [
          for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) ...[
            Expanded(child: _themeChoice(mode, selected)),
            if (mode != ThemeMode.system) const SizedBox(width: 8),
          ],
        ]),
      );

  Widget _themeChoice(ThemeMode mode, ThemeMode selected) {
    final active = mode == selected;
    final icon = mode == ThemeMode.light ? Icons.light_mode_outlined : mode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.settings_suggest_outlined;
    return InkWell(
      onTap: () => ThemeController.setMode(mode),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(children: [Icon(icon, color: active ? AppColors.primary : AppColors.textSecondary), const SizedBox(height: 6), Text(ThemeController.label(mode), style: TextStyle(fontWeight: FontWeight.w800, color: active ? AppColors.primaryDark : null))]),
      ),
    );
  }

  Widget _logoutCard() => B2BSurface(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log out', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 2),
                  Text('End this session on this device', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Log out'),
            ),
          ],
        ),
      );

  Widget _info(String label, String value, {bool last = false, Color? valueColor}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 118, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, color: valueColor))),
        ]),
      );

  Widget _stat(String label, String value, IconData icon, Color color, Color soft) => B2BSurface(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))])),
        ]),
      );
}

String _roleLabel(String? value) {
  final role = (value ?? '').trim().toLowerCase();
  if (role == 'dealer') return 'Dealer';
  if (role == 'reseller') return 'Reseller';
  if (role == 'admin') return 'Admin';
  if (role == 'client' || role == 'customer') return 'Customer';
  return role.isEmpty ? 'Account' : role;
}

String _money(double value, String currency) {
  final normalized = currency.trim().toUpperCase();
  final symbol = switch (normalized) {
    'USD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    'TRY' => '₺',
    _ => '$normalized ',
  };
  return '$symbol${NumberFormat('#,##0.00', 'en_US').format(value)}';
}
