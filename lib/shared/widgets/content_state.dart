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
            final compact = constraints.hasBoundedHeight && constraints.maxHeight < 620;
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
                        child: _SkeletonBlock(height: tileHeight, color: shimmer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SkeletonBlock(height: tileHeight, color: shimmer),
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
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
        onAction: onRetry,
      );
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(26),
        constraints: const BoxConstraints(maxWidth: 430),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(B2BRadius.xl),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 66,
              width: 66,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 31, color: iconColor),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
