import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_environment.dart';
import 'core/routing/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    AppEnvironment.validateReleaseConfiguration();
  }

  final storage = TokenStorage();
  final results = await Future.wait<Object?>([
    storage.readAccessToken(),
    storage.hasCompletedOnboarding(),
    ThemeController.initialize(),
  ]);

  final accessToken = results[0] as String?;
  final completedOnboarding = results[1] as bool;

  final initialLocation = accessToken != null && accessToken.isNotEmpty
      ? AppRoutes.dashboard
      : completedOnboarding
      ? AppRoutes.login
      : AppRoutes.onboarding;

  runApp(Roam2WorldApp(initialLocation: initialLocation));
}
