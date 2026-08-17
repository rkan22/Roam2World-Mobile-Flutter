import '../routing/app_router.dart';

String resolveInitialRoute({
  required String? accessToken,
  required bool completedOnboarding,
  required bool biometricEnabled,
}) {
  final hasSession = accessToken != null && accessToken.isNotEmpty;
  if (hasSession) {
    return biometricEnabled ? AppRoutes.biometricUnlock : AppRoutes.dashboard;
  }
  return completedOnboarding ? AppRoutes.login : AppRoutes.onboarding;
}
