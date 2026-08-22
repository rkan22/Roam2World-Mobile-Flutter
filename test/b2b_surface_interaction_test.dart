import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/design_system/components/b2b_surface.dart';

void main() {
  testWidgets('interactive surface compresses while pressed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: B2BSurface(onTap: () {}, child: const Text('Metric')),
        ),
      ),
    );

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Metric')),
    );
    await tester.pump();

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      lessThan(1),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('static surface does not add press scaling', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: B2BSurface(child: Text('Static'))),
      ),
    );

    expect(find.byType(AnimatedScale), findsNothing);
  });
}
