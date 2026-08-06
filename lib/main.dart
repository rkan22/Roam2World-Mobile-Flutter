import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_environment.dart';
import 'core/routing/app_router.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    AppEnvironment.validateReleaseConfiguration();
  }

  final storage = TokenStorage();
  final accessToken = await storage.readAccessToken();
  final completedOnboarding = await storage.hasCompletedOnboarding();

  final initialLocation = accessToken != null && accessToken.isNotEmpty
      ? AppRoutes.dashboard
      : completedOnboarding
          ? AppRoutes.login
          : AppRoutes.onboarding;

  runApp(Roam2WorldApp(initialLocation: initialLocation));
}
