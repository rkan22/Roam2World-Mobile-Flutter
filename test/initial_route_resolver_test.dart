import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/auth/initial_route_resolver.dart';
import 'package:roam2world_mobile_flutter/core/routing/app_router.dart';

void main() {
  test('first launch opens onboarding', () {
    expect(
      resolveInitialRoute(
        accessToken: null,
        completedOnboarding: false,
        biometricEnabled: false,
      ),
      AppRoutes.onboarding,
    );
  });

  test('completed onboarding without a token opens login', () {
    expect(
      resolveInitialRoute(
        accessToken: null,
        completedOnboarding: true,
        biometricEnabled: false,
      ),
      AppRoutes.login,
    );
  });

  test('active session without Face ID opens dashboard', () {
    expect(
      resolveInitialRoute(
        accessToken: 'access-token',
        completedOnboarding: true,
        biometricEnabled: false,
      ),
      AppRoutes.dashboard,
    );
  });

  test('active session with Face ID opens biometric unlock', () {
    expect(
      resolveInitialRoute(
        accessToken: 'access-token',
        completedOnboarding: true,
        biometricEnabled: true,
      ),
      AppRoutes.biometricUnlock,
    );
  });
}
