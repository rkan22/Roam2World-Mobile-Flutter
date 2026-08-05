import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_environment.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppEnvironment.apiBaseUrl,
                connectTimeout: AppEnvironment.connectTimeout,
                receiveTimeout: AppEnvironment.receiveTimeout,
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (exception, handler) async {
          final request = exception.requestOptions;
          final isUnauthorized = exception.response?.statusCode == 401;
          final isRefreshRequest = request.path == ApiEndpoints.tokenRefresh;
          final alreadyRetried = request.extra['retried_after_refresh'] == true;

          if (!isUnauthorized || isRefreshRequest || alreadyRetried) {
            handler.next(exception);
            return;
          }

          try {
            final accessToken = await _refreshAccessToken();
            if (accessToken == null || accessToken.isEmpty) {
              handler.next(exception);
              return;
            }

            request.extra['retried_after_refresh'] = true;
            request.headers['Authorization'] = 'Bearer $accessToken';
            final response = await _dio.fetch<dynamic>(request);
            handler.resolve(response);
          } catch (_) {
            await _tokenStorage.clear();
            handler.next(exception);
          }
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  Future<String?>? _refreshFuture;

  Future<String?> _refreshAccessToken() {
    final current = _refreshFuture;
    if (current != null) return current;

    final future = _performRefresh();
    _refreshFuture = future;
    return future.whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenStorage.clear();
      return null;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppEnvironment.apiBaseUrl,
        connectTimeout: AppEnvironment.connectTimeout,
        receiveTimeout: AppEnvironment.receiveTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    try {
      final response = await refreshDio.post<dynamic>(
        ApiEndpoints.tokenRefresh,
        data: {'refresh': refreshToken},
      );
      final body = response.data;
      final map = body is Map
          ? Map<String, dynamic>.from(body)
          : <String, dynamic>{};
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      final accessToken = data['access']?.toString() ?? '';
      final rotatedRefreshToken = data['refresh']?.toString();

      if (accessToken.isEmpty) {
        await _tokenStorage.clear();
        return null;
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: rotatedRefreshToken,
      );
      return accessToken;
    } on DioException {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) parser,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return parser(response.data);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    required T Function(dynamic data) parser,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return parser(response.data);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    required T Function(dynamic data) parser,
  }) async {
    try {
      final response = await _dio.put<dynamic>(path, data: data);
      return parser(response.data);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}
