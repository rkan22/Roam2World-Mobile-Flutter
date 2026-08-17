import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, expired }

class AuthState extends ChangeNotifier {
  AuthState._();

  static final AuthState instance = AuthState._();

  AuthStatus _status = AuthStatus.unknown;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void initialize({required bool hasSession}) {
    _setStatus(
      hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  void signedIn() => _setStatus(AuthStatus.authenticated);
  void signedOut() => _setStatus(AuthStatus.unauthenticated);
  void sessionExpired() => _setStatus(AuthStatus.expired);

  void _setStatus(AuthStatus value) {
    if (_status == value) return;
    _status = value;
    notifyListeners();
  }
}
