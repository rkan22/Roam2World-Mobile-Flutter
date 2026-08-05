import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'auth_session.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final session = await _apiClient.post<AuthSession>(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
      parser: (data) => AuthSession.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );

    if (session.accessToken.isEmpty) {
      throw const FormatException('Login response did not include a token.');
    }

    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  Future<void> signOut() => _tokenStorage.clear();

  Future<bool> hasSession() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
