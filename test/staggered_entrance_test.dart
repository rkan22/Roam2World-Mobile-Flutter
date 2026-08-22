import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/shared/widgets/staggered_entrance.dart';

void main() {
  testWidgets('fades and slides content into place', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StaggeredEntrance(child: Text('Package'))),
      ),
    );

    final fade = find.descendant(
      of: find.byType(StaggeredEntrance),
      matching: find.byType(FadeTransition),
    );

    expect(tester.widget<FadeTransition>(fade).opacity.value, 0);

    await tester.pumpAndSettle();

    expect(find.text('Package'), findsOneWidget);
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
  });
}
