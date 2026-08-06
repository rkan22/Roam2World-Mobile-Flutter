import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/shared/widgets/adaptive_split_view.dart';

void main() {
  Future<void> pumpSubject(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdaptiveSplitView(
            primary: SizedBox(
              key: ValueKey('primary'),
              height: 120,
            ),
            secondary: SizedBox(
              key: ValueKey('secondary'),
              height: 120,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('stacks panels on phone widths', (tester) async {
    await pumpSubject(tester, size: const Size(430, 900));

    final primary = tester.getTopLeft(find.byKey(const ValueKey('primary')));
    final secondary = tester.getTopLeft(find.byKey(const ValueKey('secondary')));

    expect(secondary.dy, greaterThan(primary.dy));
    expect(secondary.dx, primary.dx);
  });

  testWidgets('places panels side by side on tablet widths', (tester) async {
    await pumpSubject(tester, size: const Size(1180, 900));

    final primary = tester.getTopLeft(find.byKey(const ValueKey('primary')));
    final secondary = tester.getTopLeft(find.byKey(const ValueKey('secondary')));

    expect(secondary.dx, greaterThan(primary.dx));
    expect(secondary.dy, primary.dy);
  });
}
