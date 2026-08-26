import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/auth/auth_state.dart';
import 'core/auth/biometric_auth_service.dart';
import 'core/auth/initial_route_resolver.dart';
import 'core/config/app_environment.dart';
import 'core/currency/display_currency_controller.dart';
import 'core/monitoring/crash_reporting_service.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CrashReportingService.initialize();

  if (kReleaseMode) {
    AppEnvironment.validateReleaseConfiguration();
  }

  final storage = TokenStorage();
  final results = await Future.wait<Object?>([
    storage.readAccessToken(),
    storage.hasCompletedOnboarding(),
    BiometricAuthService.instance.isEnabled(),
    ThemeController.initialize(),
    DisplayCurrencyController.initialize(),
  ]);

  final accessToken = results[0] as String?;
  final completedOnboarding = results[1] as bool;
  final biometricEnabled = results[2] as bool;

  final initialLocation = resolveInitialRoute(
    accessToken: accessToken,
    completedOnboarding: completedOnboarding,
    biometricEnabled: biometricEnabled,
  );

  AuthState.instance.initialize(
    hasSession: accessToken != null && accessToken.isNotEmpty,
  );

  runApp(Roam2WorldApp(initialLocation: initialLocation));
}
