import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  factory ApiException.fromDio(DioException exception) {
    final response = exception.response;
    final data = response?.data;
    String? responseMessage;
    String? responseCode;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      responseMessage = map['message']?.toString() ??
          map['error']?.toString() ??
          map['detail']?.toString();
      responseCode = map['code']?.toString();
    }

    return ApiException(
      message: responseMessage ?? _fallbackMessage(exception.type),
      statusCode: response?.statusCode,
      code: responseCode,
    );
  }

  static String _fallbackMessage(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The request timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Unable to connect. Check your internet connection.',
      DioExceptionType.cancel => 'The request was cancelled.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() => message;
}
