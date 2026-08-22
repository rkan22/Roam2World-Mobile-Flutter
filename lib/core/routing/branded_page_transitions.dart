import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BrandedPageTransitionsBuilder extends PageTransitionsBuilder {
  const BrandedPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final fade = Tween<double>(begin: .84, end: 1).animate(curved);

    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      final cupertinoTransition = const CupertinoPageTransitionsBuilder()
          .buildTransitions<T>(
            route,
            context,
            animation,
            secondaryAnimation,
            child,
          );

      return FadeTransition(opacity: fade, child: cupertinoTransition);
    }

    final slide = Tween<Offset>(
      begin: const Offset(.035, 0),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
