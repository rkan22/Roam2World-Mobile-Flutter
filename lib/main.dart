import 'package:flutter/material.dart';

import 'app.dart';
import 'core/routing/app_router.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
