import 'package:flutter/material.dart';
import 'package:smart_retail/app/core/theme/app_theme_colors.dart';

/// Centralized color scheme for the app
class AppColors {
  static const MaterialColor primary = AppThemeColors.primary;
  static const MaterialColor secondary = AppThemeColors.secondary;

  // Role-based colors
  static const MaterialColor merchant = AppThemeColors.merchant;
  static const MaterialColor shop = AppThemeColors.shop;
  static const MaterialColor staff = AppThemeColors.staff;
  static const MaterialColor admin = AppThemeColors.admin;

  // Status colors
  static const MaterialColor success = AppThemeColors.success;
  static const MaterialColor warning = AppThemeColors.warning;
  static const MaterialColor error = AppThemeColors.error;
  static const MaterialColor info = AppThemeColors.info;

  // Gradient combinations
  static const List<Color> primaryGradientColors =
      AppThemeColors.primaryGradientColors;
  static const List<Color> successGradientColors =
      AppThemeColors.successGradientColors;
  static const List<Color> warningGradientColors =
      AppThemeColors.warningGradientColors;
  static const List<Color> errorGradientColors =
      AppThemeColors.errorGradientColors;
  static const List<Color> infoGradientColors =
      AppThemeColors.infoGradientColors;

  // Role-based gradient colors
  static const List<Color> merchantGradientColors =
      AppThemeColors.merchantGradientColors;
  static const List<Color> shopGradientColors =
      AppThemeColors.shopGradientColors;
  static const List<Color> staffGradientColors =
      AppThemeColors.staffGradientColors;
  static const List<Color> adminGradientColors =
      AppThemeColors.adminGradientColors;

  // Gradient objects
  static const LinearGradient primaryGradient = LinearGradient(
    colors: primaryGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: successGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: warningGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient errorGradient = LinearGradient(
    colors: errorGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient infoGradient = LinearGradient(
    colors: infoGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Role-based gradients
  static const LinearGradient merchantGradient = LinearGradient(
    colors: merchantGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient shopGradient = LinearGradient(
    colors: shopGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient staffGradient = LinearGradient(
    colors: staffGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient adminGradient = LinearGradient(
    colors: adminGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF667eea),
    Color(0xFF11998e),
    Color(0xFFf46b45),
    Color(0xFFeb3349),
    Color(0xFF4facfe),
    Color(0xFFf093fb),
    Color(0xFFfccb90),
    Color(0xFFa8edea),
  ];

  // Background
  static const Color backgroundGrey = AppThemeColors.background;
  static const Color cardBackground = AppThemeColors.surface;

  // Text colors
  static const Color textPrimary = AppThemeColors.textPrimary;
  static const Color textSecondary = AppThemeColors.textSecondary;
  static const Color textHint = Color(0xFF94A3B8);
}
