import 'package:flutter/material.dart';

import '../../../shared/widgets/adaptive_page.dart';
import '../../../shared/widgets/adaptive_split_view.dart';

class ReportsKpiLayout extends StatelessWidget {
  const ReportsKpiLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minItemWidth: 190,
      maxColumns: 4,
      gap: 16,
      children: children,
    );
  }
}

class ReportsInsightsLayout extends StatelessWidget {
  const ReportsInsightsLayout({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSplitView(
      primary: primary,
      secondary: secondary,
      breakpoint: 920,
      primaryFlex: 7,
      secondaryFlex: 5,
      gap: 20,
    );
  }
}
