import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/customers/widgets/customers_adaptive_grid.dart';

void main() {
  Future<void> pumpAtWidth(
    WidgetTester tester,
    double width,
  ) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomersAdaptiveGrid(
            children: [
              SizedBox(key: Key('customer-a'), height: 120),
              SizedBox(key: Key('customer-b'), height: 120),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('uses one column on phones', (tester) async {
    await pumpAtWidth(tester, 430);

    final first = tester.getTopLeft(find.byKey(const Key('customer-a')));
    final second = tester.getTopLeft(find.byKey(const Key('customer-b')));

    expect(second.dy, greaterThan(first.dy));
  });

  testWidgets('uses two columns on tablets', (tester) async {
    await pumpAtWidth(tester, 1180);

    final first = tester.getTopLeft(find.byKey(const Key('customer-a')));
    final second = tester.getTopLeft(find.byKey(const Key('customer-b')));

    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
  });
}
