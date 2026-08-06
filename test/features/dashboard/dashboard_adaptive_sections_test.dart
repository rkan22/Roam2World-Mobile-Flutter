import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/dashboard/widgets/dashboard_adaptive_sections.dart';

void main() {
  Widget buildSubject({required Size size, required Widget child}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  List<Widget> tiles(int count) => List.generate(
        count,
        (index) => SizedBox(
          key: ValueKey('tile-$index'),
          height: 80,
          child: Text('Tile $index'),
        ),
      );

  testWidgets('KPI layout wraps to two columns on phone widths', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        size: const Size(430, 900),
        child: DashboardKpiLayout(children: tiles(4)),
      ),
    );

    final first = tester.getTopLeft(find.byKey(const ValueKey('tile-0')));
    final second = tester.getTopLeft(find.byKey(const ValueKey('tile-1')));
    final third = tester.getTopLeft(find.byKey(const ValueKey('tile-2')));

    expect(first.dy, second.dy);
    expect(third.dy, greaterThan(first.dy));
  });

  testWidgets('KPI layout renders four columns on tablet widths', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        size: const Size(1180, 900),
        child: DashboardKpiLayout(children: tiles(4)),
      ),
    );

    final yPositions = [
      for (var index = 0; index < 4; index++)
        tester.getTopLeft(find.byKey(ValueKey('tile-$index'))).dy,
    ];

    expect(yPositions.toSet(), hasLength(1));
  });

  testWidgets('quick actions wrap safely on compact widths', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        size: const Size(360, 800),
        child: DashboardQuickActionsLayout(children: tiles(4)),
      ),
    );

    final first = tester.getTopLeft(find.byKey(const ValueKey('tile-0')));
    final third = tester.getTopLeft(find.byKey(const ValueKey('tile-2')));

    expect(third.dy, greaterThan(first.dy));
  });
}
