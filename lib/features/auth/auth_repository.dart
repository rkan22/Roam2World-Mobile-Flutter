import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
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
      ApiEndpoints.mobileLogin,
      data: {
        'email': email.trim(),
        'password': password,
      },
      parser: (data) => AuthSession.fromMobileLoginResponse(
        Map<String, dynamic>.from(data as Map),
      ),
    );

    if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
      throw const FormatException(
        'Login response did not include valid access and refresh tokens.',
      );
    }

    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _tokenStorage.saveProfile(session.toStoredProfile());
    return session;
  }

  Future<void> signOut() => _tokenStorage.clear();

  Future<bool> hasSession() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthSession?> readStoredProfile() async {
    final profile = await _tokenStorage.readProfile();
    return profile == null ? null : AuthSession.fromStoredProfile(profile);
  }
}
