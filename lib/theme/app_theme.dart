import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, BrandColors.light);
  static ThemeData get dark => _build(Brightness.dark, BrandColors.dark);

  static ThemeData _build(Brightness brightness, BrandColors c) {
    final base = GoogleFonts.dmSansTextTheme();
    final sans = base
        .copyWith(
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
    final textTheme = sans.copyWith(
      bodySmall: sans.bodySmall?.copyWith(color: c.textSecondary),
    );

    final radius8 = BorderRadius.circular(8);
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius8,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [c],
      scaffoldBackgroundColor: c.background,
      canvasColor: c.surfaceOverlay,
      focusColor: c.focus,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.primary,
        onSecondary: c.onPrimary,
        error: c.danger,
        onError: c.onPrimary,
        surface: c.surface,
        onSurface: c.textPrimary,
        outline: c.borderStrong,
        outlineVariant: c.border,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.inverse,
        foregroundColor: c.onInverse,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(color: c.onInverse),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius8,
          side: BorderSide(color: c.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceOverlay,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surfaceOverlay),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: radius8,
          side: BorderSide(color: c.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textMuted),
        border: inputBorder(c.borderStrong),
        enabledBorder: inputBorder(c.borderStrong),
        focusedBorder: inputBorder(c.focus, 2),
        errorBorder: inputBorder(c.danger),
        focusedErrorBorder: inputBorder(c.danger, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: radius8),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: radius8),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: c.textSecondary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      drawerTheme: DrawerThemeData(backgroundColor: c.inverse),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.background),
        actionTextColor: c.background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return c.primary;
            return c.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return c.onPrimary;
            return c.textSecondary;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: c.borderStrong)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radius8),
          ),
        ),
      ),
    );
  }
}
