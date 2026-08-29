import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/shared/widgets/content_state.dart';

void main() {
  testWidgets('renders compact error state and retry action', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContentErrorState(
            message: 'Connection unavailable.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Connection unavailable.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('renders empty state immediately with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          body: ContentEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No packages found',
            message: 'Try changing the filters.',
          ),
        ),
      ),
    );

    final scale = tester.widget<ScaleTransition>(
      find.byKey(const Key('content-state-scale')),
    );

    expect(scale.scale.value, 1);
    expect(find.text('No packages found'), findsOneWidget);
  });
}
