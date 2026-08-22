import 'package:flutter/material.dart';

enum R2WToastType { success, error, warning, info }

abstract final class R2WToast {
  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: R2WToastType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: R2WToastType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(BuildContext context, String message) {
    show(context, message, type: R2WToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: R2WToastType.info);
  }

  static void show(
    BuildContext context,
    String message, {
    R2WToastType type = R2WToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colors = _colors(theme, type);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: colors.background,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          duration: type == R2WToastType.error
              ? const Duration(seconds: 5)
              : const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.accent.withValues(alpha: .34)),
          ),
          content: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(colors.icon, size: 20, color: colors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: colors.accent,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  static _ToastColors _colors(ThemeData theme, R2WToastType type) {
    final dark = theme.brightness == Brightness.dark;
    final background = dark ? const Color(0xFF111C31) : const Color(0xFFFFFFFF);
    final foreground = dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return switch (type) {
      R2WToastType.success => _ToastColors(
        background,
        foreground,
        const Color(0xFF10B981),
        Icons.check_circle_rounded,
      ),
      R2WToastType.error => _ToastColors(
        background,
        foreground,
        const Color(0xFFEF4444),
        Icons.error_rounded,
      ),
      R2WToastType.warning => _ToastColors(
        background,
        foreground,
        const Color(0xFFF59E0B),
        Icons.warning_amber_rounded,
      ),
      R2WToastType.info => _ToastColors(
        background,
        foreground,
        theme.colorScheme.primary,
        Icons.info_rounded,
      ),
    };
  }
}

class _ToastColors {
  const _ToastColors(this.background, this.foreground, this.accent, this.icon);

  final Color background;
  final Color foreground;
  final Color accent;
  final IconData icon;
}
