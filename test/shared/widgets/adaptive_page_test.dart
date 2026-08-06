import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/shared/widgets/adaptive_page.dart';

void main() {
  testWidgets('AdaptivePage keeps phone content within compact width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdaptivePage(
            child: ColoredBox(
              key: Key('content'),
              color: Colors.black,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('content'))).width, 430);
  });

  testWidgets('AdaptivePage constrains tablet content', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdaptivePage(
            child: ColoredBox(
              key: Key('content'),
              color: Colors.black,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('content'))).width, 1180);
  });

  testWidgets('AdaptiveGrid increases columns when space is available',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveGrid(
            children: List.generate(
              4,
              (index) => SizedBox(
                key: Key('item-$index'),
                height: 80,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('item-0'))).width, greaterThan(220));
    expect(tester.getTopLeft(find.byKey(const Key('item-1'))).dy,
        tester.getTopLeft(find.byKey(const Key('item-0'))).dy);
  });
}
