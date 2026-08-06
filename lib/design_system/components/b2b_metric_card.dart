import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../tokens/b2b_tokens.dart';
import 'b2b_surface.dart';

class B2BMetricCard extends StatelessWidget {
  const B2BMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.trendPositive,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trend;
  final bool? trendPositive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trendColor = trendPositive == null
        ? AppColors.textSecondary
        : trendPositive!
            ? AppColors.success
            : AppColors.danger;

    return B2BSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (icon != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(B2BRadius.sm),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (trend != null) ...[
            const SizedBox(height: B2BSpacing.xs),
            Text(
              trend!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
