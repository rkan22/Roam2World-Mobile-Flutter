import 'package:flutter/material.dart';

import '../../../design_system/tokens/b2b_tokens.dart';
import '../../../shared/widgets/adaptive_page.dart';

/// Responsive layout for the four primary dashboard KPI cards.
///
/// Phone widths render two columns. Tablet widths naturally expand to four
/// columns without changing the card widgets themselves.
class DashboardKpiLayout extends StatelessWidget {
  const DashboardKpiLayout({
    super.key,
    required this.children,
  }) : assert(children.length == 4);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minItemWidth: 190,
      spacing: B2BSpacing.md,
      runSpacing: B2BSpacing.md,
      children: children,
    );
  }
}

/// Responsive layout for dashboard shortcuts.
///
/// Compact phones can wrap to two columns, while larger phones and tablets
/// show all four actions in one row.
class DashboardQuickActionsLayout extends StatelessWidget {
  const DashboardQuickActionsLayout({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minItemWidth: 150,
      spacing: B2BSpacing.sm,
      runSpacing: B2BSpacing.sm,
      children: children,
    );
  }
}
