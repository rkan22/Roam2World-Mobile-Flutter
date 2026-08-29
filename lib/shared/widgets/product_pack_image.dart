import 'package:flutter/material.dart';

class ProductPackImage extends StatelessWidget {
  const ProductPackImage({
    super.key,
    required this.label,
    this.width = 58,
    this.height = 76,
  });

  final String label;
  final double width;
  final double height;

  static String assetFor(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('turk') || normalized.contains('türki')) {
      return 'assets/images/products/turkiye_plan.png';
    }
    if (normalized.contains('balkan')) {
      return 'assets/images/products/balkans_plan.png';
    }
    if (normalized.contains('global') || normalized.contains('world')) {
      return 'assets/images/products/global_plan.png';
    }
    return 'assets/images/products/europe_plan.png';
  }

  @override
  Widget build(BuildContext context) => Image.asset(
    assetFor(label),
    width: width,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
  );
}
