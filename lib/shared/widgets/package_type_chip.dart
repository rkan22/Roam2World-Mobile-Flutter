import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PackageTypeChip extends StatelessWidget {
  const PackageTypeChip({
    super.key,
    required this.packageType,
    this.size = 44,
    this.iconSize = 24,
  });

  final String packageType;
  final double size;
  final double iconSize;

  bool get _isPhysicalSim => packageType.trim().toLowerCase() == 'simcard';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = _isPhysicalSim ? 'Physical SIM card' : 'eSIM';

    return Semantics(
      label: label,
      image: true,
      child: Tooltip(
        message: label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(size * .32),
            border: Border.all(color: scheme.outlineVariant),
          ),
          alignment: Alignment.center,
          child: Icon(
            _isPhysicalSim ? Icons.sim_card_rounded : Icons.memory_rounded,
            size: iconSize,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
