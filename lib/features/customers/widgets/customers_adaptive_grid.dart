import 'package:flutter/material.dart';

import '../../../shared/widgets/adaptive_page.dart';

/// Keeps customer cards in a single column on phones and promotes them to a
/// two-column CRM workspace on tablets and desktop-sized windows.
class CustomersAdaptiveGrid extends StatelessWidget {
  const CustomersAdaptiveGrid({
    super.key,
    required this.children,
    this.gap = 12,
  });

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minItemWidth: 400,
      maxColumns: 2,
      gap: gap,
      children: children,
    );
  }
}
