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
      data: {'email': email.trim(), 'password': password},
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

  Future<String> requestPasswordReset(String email) =>
      _postMessage(ApiEndpoints.passwordResetRequest, {'email': email.trim()});

  Future<String> resendPasswordResetOtp(String email) => _postMessage(
    ApiEndpoints.passwordResetResendOtp,
    {'email': email.trim()},
  );

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) => _postMessage(ApiEndpoints.passwordResetVerifyOtp, {
    'email': email.trim(),
    'otp_code': otp.trim(),
    'otp': otp.trim(),
  });

  Future<String> confirmPasswordReset({
    required String email,
    required String otp,
    required String newPassword,
  }) => _postMessage(ApiEndpoints.passwordResetConfirm, {
    'email': email.trim(),
    'otp_code': otp.trim(),
    'otp': otp.trim(),
    'new_password': newPassword,
    'confirm_password': newPassword,
  });

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _postMessage(ApiEndpoints.passwordChange, {
    'current_password': currentPassword,
    'old_password': currentPassword,
    'new_password': newPassword,
    'confirm_password': newPassword,
  });

  Future<bool> hasSession() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthSession?> readStoredProfile() async {
    final profile = await _tokenStorage.readProfile();
    return profile == null ? null : AuthSession.fromStoredProfile(profile);
  }

  Future<String> _postMessage(String path, Map<String, dynamic> data) =>
      _apiClient.post<String>(
        path,
        data: data,
        parser: (response) {
          final root = response is Map
              ? Map<String, dynamic>.from(response)
              : <String, dynamic>{};
          return (root['message'] ?? 'Request completed.').toString();
        },
      );
}
