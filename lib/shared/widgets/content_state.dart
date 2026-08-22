import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';

class ContentLoadingState extends StatefulWidget {
  final String label;
  const ContentLoadingState({super.key, this.label = 'Loading...'});

  @override
  State<ContentLoadingState> createState() => _ContentLoadingStateState();
}

class _ContentLoadingStateState extends State<ContentLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmer = Color.lerp(
          scheme.surfaceContainerHighest,
          scheme.primaryContainer.withValues(alpha: .45),
          _controller.value,
        )!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.hasBoundedHeight && constraints.maxHeight < 620;
            final heroHeight = compact ? 112.0 : 156.0;
            final tileHeight = compact ? 82.0 : 108.0;
            final rowHeight = compact ? 64.0 : 86.0;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SkeletonBlock(height: 28, widthFactor: .46, color: shimmer),
                  const SizedBox(height: 10),
                  _SkeletonBlock(height: 14, widthFactor: .68, color: shimmer),
                  SizedBox(height: compact ? 16 : 22),
                  _SkeletonBlock(
                    height: heroHeight,
                    color: shimmer,
                    radius: B2BRadius.xl,
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SkeletonBlock(
                          height: tileHeight,
                          color: shimmer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SkeletonBlock(
                          height: tileHeight,
                          color: shimmer,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  _SkeletonBlock(height: rowHeight, color: shimmer),
                  const SizedBox(height: 12),
                  _SkeletonBlock(height: rowHeight, color: shimmer),
                  SizedBox(height: compact ? 14 : 18),
                  Center(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    required this.color,
    this.widthFactor = 1,
    this.radius = B2BRadius.md,
  });

  final double height;
  final double widthFactor;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: AnimatedContainer(
        duration: B2BMotion.fast,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class ContentEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ContentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => _StateCard(
    icon: icon,
    iconColor: Theme.of(context).colorScheme.primary,
    title: title,
    message: message,
    actionLabel: actionLabel,
    actionIcon: Icons.arrow_forward_rounded,
    onAction: onAction,
  );
}

class ContentErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ContentErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => _StateCard(
    icon: Icons.error_outline_rounded,
    iconColor: AppColors.danger,
    title: title,
    message: message,
    actionLabel: onRetry == null ? null : 'Try again',
    actionIcon: Icons.refresh_rounded,
    onAction: onRetry,
  );
}

class _StateCard extends StatefulWidget {
  const _StateCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionIcon,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final IconData actionIcon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_StateCard> createState() => _StateCardState();
}

class _StateCardState extends State<_StateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: B2BMotion.standard,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: .965,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: FadeTransition(
        key: const Key('content-state-fade'),
        opacity: _opacity,
        child: ScaleTransition(
          key: const Key('content-state-scale'),
          scale: _scale,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(26),
            constraints: const BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.iconColor.withValues(alpha: isDark ? .10 : .055),
                  scheme.surface,
                  scheme.surface,
                ],
                stops: const [0, .42, 1],
              ),
              borderRadius: BorderRadius.circular(B2BRadius.xl),
              border: Border.all(
                color: widget.iconColor.withValues(alpha: isDark ? .28 : .16),
              ),
              boxShadow: isDark ? null : B2BShadows.elevated,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Roam2World B2B',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: .78),
                      borderRadius: BorderRadius.circular(B2BRadius.pill),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.travel_explore_rounded,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ROAM2WORLD  •  B2B',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .75,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.iconColor.withValues(alpha: .15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.iconColor.withValues(alpha: .12),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, size: 34, color: widget.iconColor),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: widget.onAction,
                    icon: Icon(widget.actionIcon, size: 19),
                    label: Text(widget.actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
