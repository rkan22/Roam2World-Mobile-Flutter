import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/features/checkout/order_success_screen.dart';
import 'package:roam2world_mobile_flutter/features/orders/order_result.dart';

const result = MobileOrderResult(
  orderId: '42',
  orderNumber: 'MOB-42',
  status: 'completed',
  packageName: 'Turkey 10GB',
  totalAmount: 15.50,
  currency: 'USD',
  customerName: 'Ada Lovelace',
  esimId: '7',
  installAvailable: true,
);

void main() {
  testWidgets('plays the order success celebration once', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OrderSuccessScreen(result: result)),
    );

    final scale = tester.widget<ScaleTransition>(
      find.byKey(const Key('success-check-scale')),
    );
    expect(scale.scale.value, lessThan(1));

    await tester.pumpAndSettle();

    final completedScale = tester.widget<ScaleTransition>(
      find.byKey(const Key('success-check-scale')),
    );
    expect(completedScale.scale.value, 1);
    expect(find.text('Order completed'), findsOneWidget);
    expect(find.text('MOB-42'), findsOneWidget);
  });

  testWidgets('respects reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const OrderSuccessScreen(result: result),
      ),
    );

    final scale = tester.widget<ScaleTransition>(
      find.byKey(const Key('success-check-scale')),
    );
    expect(scale.scale.value, 1);
  });
}
