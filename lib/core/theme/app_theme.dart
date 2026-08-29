import 'package:flutter/material.dart';

import '../../design_system/tokens/b2b_tokens.dart';
import '../routing/branded_page_transitions.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF090F20) : AppColors.background;
    final surface = isDark ? const Color(0xFF020817) : AppColors.card;
    final surfaceMuted = isDark
        ? const Color(0xFF1E293B)
        : AppColors.surfaceMuted;
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;
    final textMuted = isDark ? const Color(0xFF64748B) : AppColors.textMuted;
    final border = isDark ? const Color(0xFF1E293B) : AppColors.border;
    final primary = isDark ? const Color(0xFF22D0F7) : AppColors.primary;
    final primarySoft = isDark
        ? const Color(0xFF1C263F)
        : AppColors.primaryLight;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          secondary: AppColors.accent,
          surface: surface,
          error: AppColors.danger,
          outline: border,
          outlineVariant: border,
        );

    final textTheme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        height: 1.06,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: textSecondary),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      disabledColor: textMuted.withValues(alpha: .48),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      iconTheme: IconThemeData(color: textSecondary, size: 22),
      primaryIconTheme: IconThemeData(color: primary, size: 22),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: BrandedPageTransitionsBuilder(),
          TargetPlatform.iOS: BrandedPageTransitionsBuilder(),
          TargetPlatform.macOS: BrandedPageTransitionsBuilder(),
          TargetPlatform.windows: BrandedPageTransitionsBuilder(),
          TargetPlatform.linux: BrandedPageTransitionsBuilder(),
          TargetPlatform.fuchsia: BrandedPageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleSpacing: 20,
        toolbarHeight: 64,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.35,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 1,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: .28)
            : const Color(0x0D0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(B2BRadius.xl),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: primarySoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(B2BRadius.md),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? primary : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? primary
                : textSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceMuted : AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: B2BSpacing.md,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
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
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(B2BRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              backgroundColor: primary,
              foregroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(B2BRadius.md),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ).copyWith(
              animationDuration: B2BMotion.fast,
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) return 0;
                return states.contains(WidgetState.pressed) ? 0 : 3;
              }),
              shadowColor: WidgetStatePropertyAll(
                primary.withValues(alpha: .26),
              ),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withValues(alpha: .16);
                }
                return null;
              }),
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              minimumSize: const Size(0, 52),
              backgroundColor: primary,
              foregroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(B2BRadius.md),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ).copyWith(
              animationDuration: B2BMotion.fast,
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) return 0;
                return states.contains(WidgetState.pressed) ? 0 : 3;
              }),
              shadowColor: WidgetStatePropertyAll(
                primary.withValues(alpha: .26),
              ),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withValues(alpha: .16);
                }
                return null;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              foregroundColor: primary,
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : AppColors.borderStrong,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(B2BRadius.md),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ).copyWith(
              animationDuration: B2BMotion.fast,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return primary.withValues(alpha: .10);
                }
                return null;
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ).copyWith(
              animationDuration: B2BMotion.fast,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return primary.withValues(alpha: .10);
                }
                return null;
              }),
            ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: border),
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primary : textMuted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return textMuted.withValues(alpha: .55);
          }
          return states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFFF8FAFC);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return border.withValues(alpha: .7);
          }
          return states.contains(WidgetState.selected)
              ? primary
              : (isDark ? const Color(0xFF334155) : AppColors.borderStrong);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: B2BSpacing.md,
          vertical: B2BSpacing.xxs,
        ),
        minTileHeight: 58,
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 12.5,
          height: 1.35,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(B2BRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(B2BRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(B2BRadius.xl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: textMuted.withValues(alpha: .45),
        dragHandleSize: const Size(38, 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        selectedColor: primarySoft,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(B2BRadius.full),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.navy,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(B2BRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: isDark
            ? const Color(0xFF1E293B)
            : AppColors.primaryLight,
        circularTrackColor: isDark
            ? const Color(0xFF1E293B)
            : AppColors.primaryLight,
        linearMinHeight: 7,
        borderRadius: BorderRadius.circular(B2BRadius.pill),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        labelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        overlayColor: WidgetStatePropertyAll(primary.withValues(alpha: .08)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? .34 : .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(B2BRadius.md),
          side: BorderSide(color: border),
        ),
        textStyle: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFF8FAFC) : AppColors.navy,
          borderRadius: BorderRadius.circular(B2BRadius.sm),
          boxShadow: B2BShadows.card,
        ),
        textStyle: TextStyle(
          color: isDark ? AppColors.navy : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        waitDuration: const Duration(milliseconds: 450),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          iconSize: const WidgetStatePropertyAll(22),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return textMuted;
            return states.contains(WidgetState.selected)
                ? primary
                : textSecondary;
          }),
          overlayColor: WidgetStatePropertyAll(primary.withValues(alpha: .09)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(B2BRadius.sm),
            ),
          ),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(B2BRadius.pill),
        thumbColor: WidgetStatePropertyAll(textMuted.withValues(alpha: .45)),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: border)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(B2BRadius.md),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: B2BSpacing.md),
        ),
        hintStyle: WidgetStatePropertyAll(TextStyle(color: textMuted)),
        textStyle: WidgetStatePropertyAll(
          TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: primary,
        textColor: AppColors.navy,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
    );
  }
}
