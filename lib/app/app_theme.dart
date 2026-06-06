import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _black = Color(0xFF111111);
  static const _gray900 = Color(0xFF18181B);
  static const _gray700 = Color(0xFF3F3F46);
  static const _gray500 = Color(0xFF71717A);
  static const _gray200 = Color(0xFFE4E4E7);
  static const _gray100 = Color(0xFFF4F4F5);
  static const _white = Color(0xFFFFFFFF);
  static const _softWhite = Color(0xFFFBFCFC);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _black,
      brightness: Brightness.light,
    ).copyWith(
      primary: _black,
      onPrimary: _white,
      primaryContainer: _gray200,
      onPrimaryContainer: _black,
      secondary: _gray700,
      onSecondary: _white,
      secondaryContainer: _gray100,
      onSecondaryContainer: _gray900,
      tertiary: _gray500,
      onTertiary: _white,
      tertiaryContainer: _gray200,
      onTertiaryContainer: _gray900,
      surface: _white,
      onSurface: _gray900,
      surfaceContainerHighest: _gray100,
      outline: _gray500,
      outlineVariant: _gray200,
    );

    final textTheme = ThemeData.light().textTheme;

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _white,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        color: _white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.72),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _softWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _white,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.84),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _white,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
