import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class Roam2WorldApp extends StatefulWidget {
  final String initialLocation;

  const Roam2WorldApp({
    super.key,
    this.initialLocation = AppRoutes.onboarding,
  });

  @override
  State<Roam2WorldApp> createState() => _Roam2WorldAppState();
}

class _Roam2WorldAppState extends State<Roam2WorldApp> {
  late final router = createAppRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Roam2World B2B',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
