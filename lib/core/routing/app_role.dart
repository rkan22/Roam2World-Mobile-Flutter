enum AppRole { reseller, dealer, client, publicUser, admin, unknown }

AppRole parseAppRole(String? value) {
  final normalized = (value ?? '').trim().toLowerCase().replaceAll('-', '_');
  return switch (normalized) {
    'reseller' => AppRole.reseller,
    'dealer' => AppRole.dealer,
    'client' => AppRole.client,
    'public' || 'public_user' || 'customer' => AppRole.publicUser,
    'admin' || 'super_admin' || 'superadmin' => AppRole.admin,
    _ => AppRole.unknown,
  };
}

extension AppRoleX on AppRole {
  bool get isPartner => this == AppRole.reseller || this == AppRole.dealer;

  String get label => switch (this) {
    AppRole.reseller => 'Reseller',
    AppRole.dealer => 'Dealer',
    AppRole.client => 'Client',
    AppRole.publicUser => 'Customer',
    AppRole.admin => 'Admin',
    AppRole.unknown => 'Business',
  };
}
