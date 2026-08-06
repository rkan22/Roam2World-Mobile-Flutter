import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/wallet/widgets/wallet_adaptive_sections.dart';

void main() {
  Widget subject() {
    return const WalletAdaptiveSections(
      summary: SizedBox(key: ValueKey('summary'), height: 180),
      transactions: SizedBox(key: ValueKey('transactions'), height: 260),
    );
  }

  testWidgets('stacks wallet sections on phones', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: subject())));

    final summary = tester.getTopLeft(find.byKey(const ValueKey('summary')));
    final transactions =
        tester.getTopLeft(find.byKey(const ValueKey('transactions')));

    expect(transactions.dy, greaterThan(summary.dy));
  });

  testWidgets('places wallet sections side by side on tablets', (tester) async {
    tester.view.physicalSize = const Size(1180, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: subject())));

    final summary = tester.getTopLeft(find.byKey(const ValueKey('summary')));
    final transactions =
        tester.getTopLeft(find.byKey(const ValueKey('transactions')));

    expect(transactions.dx, greaterThan(summary.dx));
    expect(transactions.dy, summary.dy);
  });
}
