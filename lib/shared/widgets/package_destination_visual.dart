import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PackageDestinationVisual extends StatelessWidget {
  const PackageDestinationVisual({
    super.key,
    required this.code,
    required this.destinationKey,
    required this.size,
  });

  final String code;
  final String destinationKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalizedCode = code.trim().toUpperCase();
    final normalizedDestination = destinationKey.trim().toLowerCase();
    final isEurope =
        normalizedDestination == 'europe' || normalizedCode == 'EU';

    final url = isEurope
        ? 'https://flagcdn.com/w160/eu.png'
        : normalizedCode.length == 2
        ? 'https://flagcdn.com/w80/${normalizedCode.toLowerCase()}.png'
        : null;

    if (url == null) {
      return Icon(
        Icons.public_rounded,
        color: AppColors.primary,
        size: size * .72,
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.public_rounded,
          color: AppColors.primary,
          size: size * .72,
        ),
      ),
    );
  }
}
