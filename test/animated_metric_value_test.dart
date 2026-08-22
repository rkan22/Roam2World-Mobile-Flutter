import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/shared/widgets/animated_metric_value.dart';

void main() {
  testWidgets('animates formatted currency to its target', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnimatedMetricValue(value: 'USD 12,345.67')),
      ),
    );

    expect(find.text('USD 0.00'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('USD 12,345.67'), findsOneWidget);
  });

  testWidgets('shows a hidden balance without animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnimatedMetricValue(value: '••••••••')),
      ),
    );

    expect(find.text('••••••••'), findsOneWidget);
  });
}
