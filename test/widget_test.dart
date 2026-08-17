import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/app.dart';
import 'package:roam2world_mobile_flutter/features/auth/login_screen.dart';

void main() {
  testWidgets('app opens with onboarding', (tester) async {
    await tester.pumpWidget(const Roam2WorldApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Global connectivity, ready when you are'),
      findsOneWidget,
    );
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('login shows validation messages', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final signIn = find.text('Open workspace');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pump();

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final visibilityButton = find.byIcon(Icons.visibility_outlined);
    expect(visibilityButton, findsOneWidget);
    await tester.ensureVisible(visibilityButton);
    await tester.tap(visibilityButton);
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
