import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

abstract final class CrashReportingService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
      return true;
    };
  }

  static Future<void> recordApiFailure(DioException exception) async {
    if (kDebugMode || exception.type == DioExceptionType.cancel) return;

    final statusCode = exception.response?.statusCode;
    final isServerError = statusCode != null && statusCode >= 500;
    final isNetworkError = statusCode == null;

    if (!isServerError && !isNetworkError) return;

    final method = exception.requestOptions.method.toUpperCase();
    final path = _sanitizeApiPath(exception.requestOptions.uri.path);
    final errorType = exception.type.name;

    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCustomKey('api_method', method);
      await crashlytics.setCustomKey('api_path', path);
      await crashlytics.setCustomKey('api_status_code', statusCode ?? -1);
      await crashlytics.setCustomKey('api_error_type', errorType);

      await crashlytics.recordError(
        StateError(
          'API request failed: $method $path '
          'status=${statusCode ?? 'network'} type=$errorType',
        ),
        exception.stackTrace,
        reason: 'API request failure',
        fatal: false,
      );
    } catch (_) {
      // Monitoring must never break the application request flow.
    }
  }

  static String _sanitizeApiPath(String path) {
    final numericId = RegExp(r'^\d+$');
    final uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F-]{27,}$');

    return path
        .split('?')
        .first
        .split('/')
        .map((segment) {
          if (numericId.hasMatch(segment) ||
              uuid.hasMatch(segment) ||
              segment.contains('@') ||
              segment.length > 32) {
            return ':id';
          }
          return segment;
        })
        .join('/');
  }
}
