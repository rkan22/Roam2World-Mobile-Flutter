import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/orders/widgets/orders_adaptive_grid.dart';

void main() {
  Future<void> pumpGrid(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: OrdersAdaptiveGrid(
              children: [
                SizedBox(key: Key('first'), height: 120),
                SizedBox(key: Key('second'), height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses one column on phones', (tester) async {
    await pumpGrid(tester, const Size(430, 900));

    final first = tester.getTopLeft(find.byKey(const Key('first')));
    final second = tester.getTopLeft(find.byKey(const Key('second')));

    expect(second.dx, first.dx);
    expect(second.dy, greaterThan(first.dy));
  });

  testWidgets('uses two columns on tablets', (tester) async {
    await pumpGrid(tester, const Size(1180, 900));

    final first = tester.getTopLeft(find.byKey(const Key('first')));
    final second = tester.getTopLeft(find.byKey(const Key('second')));

    expect(second.dx, greaterThan(first.dx));
    expect(second.dy, first.dy);
  });
}
