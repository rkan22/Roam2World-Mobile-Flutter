class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.email,
    this.refreshToken,
    this.displayName,
  });

  final String accessToken;
  final String? refreshToken;
  final String userId;
  final String email;
  final String? displayName;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userData = user is Map<String, dynamic> ? user : json;

    return AuthSession(
      accessToken: json['accessToken']?.toString() ??
          json['access_token']?.toString() ??
          '',
      refreshToken: json['refreshToken']?.toString() ??
          json['refresh_token']?.toString(),
      userId: userData['id']?.toString() ?? '',
      email: userData['email']?.toString() ?? '',
      displayName: userData['name']?.toString() ??
          userData['displayName']?.toString(),
    );
  }
}
