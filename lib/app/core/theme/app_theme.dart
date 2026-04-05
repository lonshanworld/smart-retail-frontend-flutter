import 'package:flutter/material.dart';
import 'app_theme_colors.dart';
// Using bundled local fonts to support offline mode (do not fetch at runtime)

class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppThemeColors.primary,
          brightness: Brightness.light,
          surface: AppThemeColors.surface,
        ).copyWith(
          primary: AppThemeColors.primary,
          secondary: AppThemeColors.secondary,
          surface: AppThemeColors.surface,
          error: AppThemeColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppThemeColors.textPrimary,
          onError: Colors.white,
        );

    return ThemeData(
      fontFamily: 'Manrope',
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppThemeColors.background,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: AppThemeColors.textPrimary,
        displayColor: AppThemeColors.textPrimary,
        fontFamily: 'Manrope',
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppThemeColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: AppThemeColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppThemeColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppThemeColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppThemeColors.primary,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppThemeColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      dividerColor: AppThemeColors.border,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
