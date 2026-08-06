import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/profile/settings_screen.dart';

void main() {
  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('language selector shows supported languages', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('App language'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsWidgets);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
  });

  testWidgets('appearance selector shows all theme modes', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Follow device appearance'), findsOneWidget);
  });
}
