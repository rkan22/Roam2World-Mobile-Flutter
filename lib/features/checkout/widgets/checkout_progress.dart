import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CheckoutProgress extends StatelessWidget {
  const CheckoutProgress({super.key, required this.currentStep});

  final int currentStep;

  static const _labels = <String>['Cart', 'Details', 'Review', 'Success'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Checkout step ${currentStep + 1} of ${_labels.length}',
      child: Row(
        children: [
          for (var index = 0; index < _labels.length; index++) ...[
            Expanded(
              flex: 0,
              child: _ProgressStep(
                number: index + 1,
                label: _labels[index],
                active: index <= currentStep,
                current: index == currentStep,
                theme: theme,
              ),
            ),
            if (index < _labels.length - 1)
              Expanded(
                child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: index < currentStep
                      ? AppColors.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.number,
    required this.label,
    required this.active,
    required this.current,
    required this.theme,
  });

  final int number;
  final String label;
  final bool active;
  final bool current;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final foreground = active
        ? AppColors.primary
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: current
                ? AppColors.primary
                : active
                ? AppColors.primaryLight
                : theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? AppColors.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            '$number',
            style: theme.textTheme.labelSmall?.copyWith(
              color: current ? Colors.white : foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: current ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
