import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile/features/reports/widgets/reports_adaptive_sections.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    Widget child,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('KPI cards use two columns on phone', (tester) async {
    final children = List.generate(4, (index) => SizedBox(key: ValueKey(index), height: 80));
    await pumpAt(tester, const Size(430, 900), ReportsKpiLayout(children: children));

    expect(tester.getTopLeft(find.byKey(const ValueKey(0))).dy,
        tester.getTopLeft(find.byKey(const ValueKey(1))).dy);
    expect(tester.getTopLeft(find.byKey(const ValueKey(2))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey(0))).dy));
  });

  testWidgets('KPI cards use four columns on tablet', (tester) async {
    final children = List.generate(4, (index) => SizedBox(key: ValueKey(index), height: 80));
    await pumpAt(tester, const Size(1180, 900), ReportsKpiLayout(children: children));

    final top = tester.getTopLeft(find.byKey(const ValueKey(0))).dy;
    for (var index = 1; index < 4; index++) {
      expect(tester.getTopLeft(find.byKey(ValueKey(index))).dy, top);
    }
  });

  testWidgets('insights stack on phone and split on tablet', (tester) async {
    const primary = SizedBox(key: ValueKey('primary'), height: 120);
    const secondary = SizedBox(key: ValueKey('secondary'), height: 120);

    await pumpAt(
      tester,
      const Size(430, 900),
      const ReportsInsightsLayout(primary: primary, secondary: secondary),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('secondary'))).dy,
      greaterThan(tester.getTopLeft(find.byKey(const ValueKey('primary'))).dy),
    );

    await pumpAt(
      tester,
      const Size(1180, 900),
      const ReportsInsightsLayout(primary: primary, secondary: secondary),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('secondary'))).dy,
      tester.getTopLeft(find.byKey(const ValueKey('primary'))).dy,
    );
  });
}
