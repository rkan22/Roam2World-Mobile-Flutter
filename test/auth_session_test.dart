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

  test('returns empty tokens for a malformed response', () {
    final session = AuthSession.fromMobileLoginResponse({
      'success': true,
      'data': <String, dynamic>{},
    });

    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, isEmpty);
  });
}
