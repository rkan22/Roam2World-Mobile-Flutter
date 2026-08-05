import 'package:dio/dio.dart';

import '../config/app_environment.dart';
import '../storage/token_storage.dart';
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
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

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
