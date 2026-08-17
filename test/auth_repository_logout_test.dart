import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/api/api_client.dart';
import 'package:roam2world_mobile_flutter/core/api/api_endpoints.dart';
import 'package:roam2world_mobile_flutter/core/auth/auth_state.dart';
import 'package:roam2world_mobile_flutter/core/storage/token_storage.dart';
import 'package:roam2world_mobile_flutter/features/auth/auth_repository.dart';

class _LogoutTokenStorage extends TokenStorage {
  _LogoutTokenStorage({this.refreshToken});

  String? refreshToken;
  int clearCount = 0;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<String?> readAccessToken() async => 'access-token';

  @override
  Future<void> clear() async {
    clearCount++;
    refreshToken = null;
  }
}

class _LogoutHttpAdapter implements HttpClientAdapter {
  _LogoutHttpAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _response(int statusCode, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  setUp(() => AuthState.instance.signedIn());

  test(
    'signOut blacklists refresh token before clearing local session',
    () async {
      final storage = _LogoutTokenStorage(refreshToken: 'refresh-token');
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      var logoutRequests = 0;

      dio.httpClientAdapter = _LogoutHttpAdapter((options) async {
        logoutRequests++;
        expect(options.path, ApiEndpoints.logout);
        expect(options.data, {'refresh_token': 'refresh-token'});
        expect(options.headers['Authorization'], 'Bearer access-token');
        return _response(200, {'success': true});
      });

      final repository = AuthRepository(
        apiClient: ApiClient(dio: dio, tokenStorage: storage),
        tokenStorage: storage,
      );

      await repository.signOut();

      expect(logoutRequests, 1);
      expect(storage.clearCount, 1);
      expect(storage.refreshToken, isNull);
      expect(AuthState.instance.status, AuthStatus.unauthenticated);
    },
  );

  test('signOut clears local session when server logout fails', () async {
    final storage = _LogoutTokenStorage(refreshToken: 'refresh-token');
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));

    dio.httpClientAdapter = _LogoutHttpAdapter(
      (_) async => _response(500, {'error': 'Unavailable'}),
    );

    final repository = AuthRepository(
      apiClient: ApiClient(dio: dio, tokenStorage: storage),
      tokenStorage: storage,
    );

    await repository.signOut();

    expect(storage.clearCount, 1);
    expect(storage.refreshToken, isNull);
    expect(AuthState.instance.status, AuthStatus.unauthenticated);
  });
}
