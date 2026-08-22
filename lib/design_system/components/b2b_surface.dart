import 'package:flutter/material.dart';

import '../tokens/b2b_tokens.dart';

class B2BSurface extends StatefulWidget {
  const B2BSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(B2BSpacing.md),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.radius = B2BRadius.xl,
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
  State<B2BSurface> createState() => _B2BSurfaceState();
}

class _B2BSurfaceState extends State<B2BSurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final interactive = widget.onTap != null;
    final pressed = interactive && _pressed && !disableAnimations;
    final duration = disableAnimations ? Duration.zero : B2BMotion.fast;
    final resolvedBackground = widget.backgroundColor ?? scheme.surface;
    final resolvedBorder = widget.borderColor ?? scheme.outlineVariant;

    final decorated = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: resolvedBorder.withValues(
            alpha: pressed ? .55 : (isDark ? .9 : .78),
          ),
        ),
        boxShadow: widget.showShadow && !isDark
            ? (pressed ? const <BoxShadow>[] : B2BShadows.elevated)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Material(
          color: Colors.transparent,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    if (!interactive) return decorated;

    return AnimatedScale(
      scale: pressed ? .985 : 1,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          borderRadius: BorderRadius.circular(widget.radius),
          splashColor: scheme.primary.withValues(alpha: .10),
          highlightColor: scheme.primary.withValues(alpha: .045),
          child: decorated,
        ),
      ),
    );
  }
}
