import 'package:flutter/material.dart';

import '../../design_system/tokens/b2b_tokens.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF08111F) : AppColors.background;
    final surface = isDark ? const Color(0xFF111C2E) : AppColors.card;
    final surfaceMuted = isDark ? const Color(0xFF17243A) : AppColors.surfaceMuted;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary;
    final textSecondary = isDark ? const Color(0xFFB5C2D6) : AppColors.textSecondary;
    final textMuted = isDark ? const Color(0xFF7F8DA3) : AppColors.textMuted;
    final border = isDark ? const Color(0xFF26344A) : AppColors.border;
    final primarySoft = isDark ? const Color(0xFF193C78) : AppColors.primaryLight;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
      surface: surface,
      error: AppColors.danger,
    );

    final textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: textPrimary,
      ),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: textSecondary),
      bodySmall: TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'SF Pro Display',
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: .24)
            : const Color(0x140F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(B2BRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        elevation: 8,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: .32)
            : const Color(0x140F172A),
        indicatorColor: primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? colorScheme.primary : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected) ? colorScheme.primary : textSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: B2BSpacing.md, vertical: 15),
        hintStyle: TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(B2BRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(B2BRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(B2BRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: colorScheme.primary,
          foregroundColor: isDark ? const Color(0xFF07111F) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(B2BRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(B2BRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: isDark ? const Color(0xFF315A91) : AppColors.primarySoft),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(B2BRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      dialogTheme: DialogThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        selectedColor: primarySoft,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(B2BRadius.full)),
      ),
    );
  }
}
