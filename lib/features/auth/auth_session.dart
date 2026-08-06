class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.role,
    this.displayName,
    this.account,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final String role;
  final String? displayName;
  final Map<String, dynamic>? account;

  factory AuthSession.fromMobileLoginResponse(Map<String, dynamic> json) {
    final responseData = _asMap(json['data']);
    final tokens = _asMap(responseData['tokens']);
    final user = _asMap(responseData['user']);
    final account = _asMap(responseData['account']);

    final firstName = user['first_name']?.toString().trim() ?? '';
    final lastName = user['last_name']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();

    return AuthSession(
      accessToken: tokens['access']?.toString() ?? '',
      refreshToken: tokens['refresh']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      role: user['role']?.toString() ?? responseData['role']?.toString() ?? '',
      displayName: fullName.isEmpty ? user['name']?.toString() : fullName,
      account: account.isEmpty ? null : account,
    );
  }

  factory AuthSession.fromStoredProfile(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: '',
      refreshToken: '',
      userId: json['user_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      account: _asMap(json['account']).isEmpty ? null : _asMap(json['account']),
    );
  }

  Map<String, dynamic> toStoredProfile() => {
        'user_id': userId,
        'email': email,
        'role': role,
        'display_name': displayName,
        'account': account,
      };

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
