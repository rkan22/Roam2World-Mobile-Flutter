import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/routing/branded_page_transitions.dart';

void main() {
  testWidgets('uses branded fade and slide on Android', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) {
            final route = MaterialPageRoute<void>(
              builder: (_) => const SizedBox(),
            );
            final transition = const BrandedPageTransitionsBuilder()
                .buildTransitions<void>(
                  route,
                  context,
                  const AlwaysStoppedAnimation(.5),
                  const AlwaysStoppedAnimation(0),
                  const SizedBox(key: Key('page')),
                );

            return KeyedSubtree(
              key: const Key('branded-transition'),
              child: transition,
            );
          },
        ),
      ),
    );

    final root = find.byKey(const Key('branded-transition'));
    final fades = find.descendant(
      of: root,
      matching: find.byType(FadeTransition),
    );
    final slides = find.descendant(
      of: root,
      matching: find.byType(SlideTransition),
    );

    expect(fades, findsOneWidget);
    expect(slides, findsOneWidget);
    expect(find.byKey(const Key('page')), findsOneWidget);
  });

  testWidgets('disables custom motion when reduce motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: Builder(
            builder: (context) {
              final route = MaterialPageRoute<void>(
                builder: (_) => const SizedBox(),
              );
              final transition = const BrandedPageTransitionsBuilder()
                  .buildTransitions<void>(
                    route,
                    context,
                    const AlwaysStoppedAnimation(.5),
                    const AlwaysStoppedAnimation(0),
                    const SizedBox(key: Key('reduced-page')),
                  );

              return KeyedSubtree(
                key: const Key('reduced-transition'),
                child: transition,
              );
            },
          ),
        ),
      ),
    );

    final root = find.byKey(const Key('reduced-transition'));
    final slides = find.descendant(
      of: root,
      matching: find.byType(SlideTransition),
    );

    expect(find.byKey(const Key('reduced-page')), findsOneWidget);
    expect(slides, findsNothing);
  });
}
