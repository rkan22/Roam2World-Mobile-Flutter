import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                storageNamespace: 'roam2world_b2b_auth',
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.unlocked_this_device,
                accountName: 'com.roam2world.b2b.auth',
              ),
            );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _profileKey = 'auth_profile';
  static const _onboardingCompletedKey = 'onboarding_completed';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<bool> hasCompletedOnboarding() async {
    return await _storage.read(key: _onboardingCompletedKey) == 'true';
  }

  Future<void> markOnboardingCompleted() {
    return _storage.write(key: _onboardingCompletedKey, value: 'true');
  }

  Future<Map<String, dynamic>?> readProfile() async {
    final raw = await _storage.read(key: _profileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> saveProfile(Map<String, dynamic> profile) {
    return _storage.write(key: _profileKey, value: jsonEncode(profile));
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _profileKey),
    ]);
  }
}
