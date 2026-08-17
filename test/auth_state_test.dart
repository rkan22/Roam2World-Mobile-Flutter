import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/auth/auth_state.dart';

void main() {
  final auth = AuthState.instance;

  setUp(() => auth.signedOut());

  test('initializes an existing session as authenticated', () {
    auth.initialize(hasSession: true);
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.isAuthenticated, isTrue);
  });

  test('marks an expired session and notifies listeners', () {
    auth.signedIn();
    var notifications = 0;
    void listener() => notifications++;
    auth.addListener(listener);

    auth.sessionExpired();

    expect(auth.status, AuthStatus.expired);
    expect(auth.isAuthenticated, isFalse);
    expect(notifications, 1);
    auth.removeListener(listener);
  });

  test('does not notify when status does not change', () {
    auth.signedOut();
    var notifications = 0;
    void listener() => notifications++;
    auth.addListener(listener);

    auth.signedOut();

    expect(notifications, 0);
    auth.removeListener(listener);
  });
}
