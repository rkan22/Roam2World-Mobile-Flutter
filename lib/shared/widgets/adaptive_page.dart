import 'package:flutter/material.dart';

/// Constrains business screens on tablets and desktop-sized windows while
/// preserving the current full-width phone layout.
class AdaptivePage extends StatelessWidget {
  const AdaptivePage({
    super.key,
    required this.child,
    this.compactMaxWidth = 760,
    this.expandedMaxWidth = 1180,
    this.breakpoint = 900,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double compactMaxWidth;
  final double expandedMaxWidth;
  final double breakpoint;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= breakpoint
            ? expandedMaxWidth
            : compactMaxWidth;

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(width: double.infinity, child: child),
          ),
        );
      },
    );
  }
}

/// Responsive grid helper used by KPI and summary cards.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 220,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columnCount = ((availableWidth + spacing) /
                (minItemWidth + spacing))
            .floor()
            .clamp(1, children.length);
        final itemWidth =
            (availableWidth - (spacing * (columnCount - 1))) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
