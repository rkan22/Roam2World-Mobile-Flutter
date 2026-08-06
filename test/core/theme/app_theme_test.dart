import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam2world_mobile_flutter/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('builds a light Material 3 theme', () {
      final theme = AppTheme.light();

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, isNot(theme.colorScheme.surface));
    });

    test('builds a dark Material 3 theme with dark surfaces', () {
      final theme = AppTheme.dark();

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(
        ThemeData.estimateBrightnessForColor(theme.scaffoldBackgroundColor),
        Brightness.dark,
      );
      expect(
        ThemeData.estimateBrightnessForColor(theme.colorScheme.surface),
        Brightness.dark,
      );
    });

    test('keeps primary actions readable in both modes', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final primary = theme.colorScheme.primary;
        final onPrimary = theme.colorScheme.onPrimary;

        expect(
          ThemeData.estimateBrightnessForColor(primary),
          isNot(ThemeData.estimateBrightnessForColor(onPrimary)),
        );
      }
    });
  });
}
