import 'package:flutter/material.dart';

import '../tokens/b2b_tokens.dart';

class B2BSurface extends StatelessWidget {
  const B2BSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(B2BSpacing.md),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.radius = B2BRadius.lg,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final resolvedBackground = backgroundColor ?? scheme.surface;
    final resolvedBorder = borderColor ?? scheme.outlineVariant;

    final content = AnimatedContainer(
      duration: B2BMotion.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: resolvedBorder),
        boxShadow: showShadow && !isDark ? B2BShadows.card : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
