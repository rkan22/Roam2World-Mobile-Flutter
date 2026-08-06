import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/auth/auth_session.dart';

void main() {
  test('parses the backend mobile login response', () {
    final session = AuthSession.fromMobileLoginResponse({
      'success': true,
      'data': {
        'user': {
          'id': 42,
          'email': 'dealer@example.com',
          'first_name': 'Ada',
          'last_name': 'Lovelace',
          'role': 'dealer',
        },
        'tokens': {
          'access': 'access-token',
          'refresh': 'refresh-token',
        },
        'account': {
          'currency': 'USD',
          'current_balance': '125.00',
        },
      },
    });

    expect(session.accessToken, 'access-token');
    expect(session.refreshToken, 'refresh-token');
    expect(session.userId, '42');
    expect(session.email, 'dealer@example.com');
    expect(session.role, 'dealer');
    expect(session.displayName, 'Ada Lovelace');
    expect(session.account?['currency'], 'USD');
  });

  test('round-trips the stored authenticated profile without tokens', () {
    const session = AuthSession(
      accessToken: 'secret-access',
      refreshToken: 'secret-refresh',
      userId: '7',
      email: 'reseller@example.com',
      role: 'reseller',
      displayName: 'Grace Hopper',
      account: {'currency': 'EUR'},
    );

    final restored = AuthSession.fromStoredProfile(session.toStoredProfile());

    expect(restored.accessToken, isEmpty);
    expect(restored.refreshToken, isEmpty);
    expect(restored.userId, '7');
    expect(restored.email, 'reseller@example.com');
    expect(restored.role, 'reseller');
    expect(restored.displayName, 'Grace Hopper');
    expect(restored.account?['currency'], 'EUR');
  });

  test('returns empty tokens for a malformed response', () {
    final session = AuthSession.fromMobileLoginResponse({
      'success': true,
      'data': <String, dynamic>{},
    });

    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, isEmpty);
  });
}
