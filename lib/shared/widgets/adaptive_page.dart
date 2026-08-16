import 'dart:math' as math;

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
    this.maxColumns,
    this.spacing = 16,
    this.runSpacing,
    this.gap,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int? maxColumns;
  final double spacing;
  final double? runSpacing;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedSpacing = gap ?? spacing;
        final availableWidth = constraints.maxWidth;
        final calculatedColumns =
            ((availableWidth + resolvedSpacing) /
                    (minItemWidth + resolvedSpacing))
                .floor();
        final columnLimit = maxColumns == null
            ? children.length
            : math.min(children.length, maxColumns!);
        final columnCount = calculatedColumns.clamp(1, columnLimit);
        final itemWidth =
            (availableWidth - (resolvedSpacing * (columnCount - 1))) /
            columnCount;

        return Wrap(
          spacing: resolvedSpacing,
          runSpacing: runSpacing ?? resolvedSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
