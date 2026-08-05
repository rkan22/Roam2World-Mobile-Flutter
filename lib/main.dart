import 'package:flutter/material.dart';

import 'app.dart';
import 'core/routing/app_router.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final accessToken = await TokenStorage().readAccessToken();
  final initialLocation = accessToken != null && accessToken.isNotEmpty
      ? AppRoutes.dashboard
      : AppRoutes.onboarding;

  runApp(Roam2WorldApp(initialLocation: initialLocation));
}
