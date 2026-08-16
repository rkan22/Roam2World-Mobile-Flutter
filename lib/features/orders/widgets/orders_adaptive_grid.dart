import 'package:flutter/material.dart';

import '../../../shared/widgets/adaptive_page.dart';

/// Keeps orders in a single column on phones and promotes them to a
/// two-column workspace on tablets and desktop-sized windows.
class OrdersAdaptiveGrid extends StatelessWidget {
  const OrdersAdaptiveGrid({super.key, required this.children, this.gap = 12});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minItemWidth: 420,
      maxColumns: 2,
      gap: gap,
      children: children,
    );
  }
}
