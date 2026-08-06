import 'package:flutter/material.dart';

/// Keeps the complete mobile workspace comfortable on tablets and resizable
/// windows. Phone layouts remain edge-to-edge, while wider screens receive a
/// centered app canvas instead of stretching every card and navigation item.
class AdaptiveAppFrame extends StatelessWidget {
  const AdaptiveAppFrame({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.tabletBreakpoint = 900,
  });

  final Widget child;
  final double maxWidth;
  final double tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < tabletBreakpoint) return child;

        final background = Theme.of(context).scaffoldBackgroundColor;
        return ColoredBox(
          color: background,
          child: SafeArea(
            left: false,
            right: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ClipRect(
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
