import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService._();

  static final BiometricAuthService instance = BiometricAuthService._();

  static const _enabledKey = 'biometric_quick_unlock_enabled';
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    return await _storage.read(key: _enabledKey) == 'true';
  }

  Future<bool> authenticate({
    String reason = 'Use Face ID to unlock your Roam2World workspace.',
  }) async {
    try {
      if (!await isAvailable()) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> enable() async {
    final authenticated = await authenticate(
      reason: 'Confirm Face ID to enable quick login.',
    );
    if (authenticated) {
      await _storage.write(key: _enabledKey, value: 'true');
    }
    return authenticated;
  }

  Future<void> disable() => _storage.delete(key: _enabledKey);
}
