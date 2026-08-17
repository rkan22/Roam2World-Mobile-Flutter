import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/api/api_client.dart';
import 'package:roam2world_mobile_flutter/core/api/api_endpoints.dart';
import 'package:roam2world_mobile_flutter/core/auth/auth_state.dart';
import 'package:roam2world_mobile_flutter/core/storage/token_storage.dart';

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  var clearCount = 0;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    this.accessToken = accessToken;
    if (refreshToken != null) this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    accessToken = null;
    refreshToken = null;
  }
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.handler);

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

ResponseBody _jsonResponse(int statusCode, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  setUp(() => AuthState.instance.signedOut());

  test('401 refreshes the token and retries the original request', () async {
    final storage = _MemoryTokenStorage(
      accessToken: 'expired-access',
      refreshToken: 'valid-refresh',
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    var requestCount = 0;

    dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
      requestCount++;
      if (requestCount == 1) {
        expect(options.headers['Authorization'], 'Bearer expired-access');
        return _jsonResponse(401, {'detail': 'Token expired'});
      }
      expect(options.headers['Authorization'], 'Bearer fresh-access');
      return _jsonResponse(200, {'ok': true});
    });

    refreshDio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
      expect(options.path, ApiEndpoints.tokenRefresh);
      expect(options.data, {'refresh': 'valid-refresh'});
      return _jsonResponse(200, {
        'access': 'fresh-access',
        'refresh': 'rotated-refresh',
      });
    });

    final client = ApiClient(
      dio: dio,
      refreshDio: refreshDio,
      tokenStorage: storage,
    );

    final result = await client.get<Map<String, dynamic>>(
      '/protected/',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    expect(result, {'ok': true});
    expect(requestCount, 2);
    expect(storage.accessToken, 'fresh-access');
    expect(storage.refreshToken, 'rotated-refresh');
  });

  test('401 without a refresh token expires the session', () async {
    final storage = _MemoryTokenStorage(accessToken: 'expired-access');
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dio.httpClientAdapter = _FakeHttpClientAdapter(
      (_) async => _jsonResponse(401, {'detail': 'Token expired'}),
    );
    final client = ApiClient(dio: dio, tokenStorage: storage);
    AuthState.instance.signedIn();

    await expectLater(
      client.get<dynamic>('/protected/', parser: (data) => data),
      throwsA(anything),
    );

    expect(AuthState.instance.status, AuthStatus.expired);
    expect(storage.accessToken, isNull);
    expect(storage.clearCount, greaterThan(0));
  });
}
