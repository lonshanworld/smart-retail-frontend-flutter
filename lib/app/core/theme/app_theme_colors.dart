import 'package:flutter/material.dart';

class AppThemeColors {
  static const MaterialColor primary = MaterialColor(0xFF4F46E5, {
    50: Color(0xFFEEF2FF),
    100: Color(0xFFE0E7FF),
    200: Color(0xFFC7D2FE),
    300: Color(0xFFA5B4FC),
    400: Color(0xFF818CF8),
    500: Color(0xFF6366F1),
    600: Color(0xFF4F46E5),
    700: Color(0xFF4338CA),
    800: Color(0xFF3730A3),
    900: Color(0xFF312E81),
  });

  static const MaterialColor secondary = MaterialColor(0xFF0EA5E9, {
    50: Color(0xFFF0F9FF),
    100: Color(0xFFE0F2FE),
    200: Color(0xFFBAE6FD),
    300: Color(0xFF7DD3FC),
    400: Color(0xFF38BDF8),
    500: Color(0xFF0EA5E9),
    600: Color(0xFF0284C7),
    700: Color(0xFF0369A1),
    800: Color(0xFF075985),
    900: Color(0xFF0C4A6E),
  });

  static const MaterialColor merchant = primary;
  static const MaterialColor shop = MaterialColor(0xFF059669, {
    50: Color(0xFFECFDF5),
    100: Color(0xFFD1FAE5),
    200: Color(0xFFA7F3D0),
    300: Color(0xFF6EE7B7),
    400: Color(0xFF34D399),
    500: Color(0xFF10B981),
    600: Color(0xFF059669),
    700: Color(0xFF047857),
    800: Color(0xFF065F46),
    900: Color(0xFF064E3B),
  });

  static const MaterialColor staff = MaterialColor(0xFFEA580C, {
    50: Color(0xFFFFF7ED),
    100: Color(0xFFFFEDD5),
    200: Color(0xFFFED7AA),
    300: Color(0xFFFDBA74),
    400: Color(0xFFFB923C),
    500: Color(0xFFF97316),
    600: Color(0xFFEA580C),
    700: Color(0xFFC2410C),
    800: Color(0xFF9A3412),
    900: Color(0xFF7C2D12),
  });

  static const MaterialColor admin = MaterialColor(0xFF1D4ED8, {
    50: Color(0xFFEFF6FF),
    100: Color(0xFFDBEAFE),
    200: Color(0xFFBFDBFE),
    300: Color(0xFF93C5FD),
    400: Color(0xFF60A5FA),
    500: Color(0xFF3B82F6),
    600: Color(0xFF2563EB),
    700: Color(0xFF1D4ED8),
    800: Color(0xFF1E40AF),
    900: Color(0xFF1E3A8A),
  });

  static const MaterialColor success = shop;
  static const MaterialColor warning = staff;
  static const MaterialColor error = Colors.red;
  static const MaterialColor info = secondary;

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color border = Color(0xFFE2E8F0);

  static const List<Color> primaryGradientColors = [
    Color(0xFF6366F1),
    Color(0xFF4F46E5),
  ];

  static const List<Color> merchantGradientColors = [
    Color(0xFF6366F1),
    Color(0xFF4338CA),
  ];

  static const List<Color> shopGradientColors = [
    Color(0xFF10B981),
    Color(0xFF047857),
  ];

  static const List<Color> staffGradientColors = [
    Color(0xFFF97316),
    Color(0xFFC2410C),
  ];

  static const List<Color> adminGradientColors = [
    Color(0xFF3B82F6),
    Color(0xFF1E40AF),
  ];

  static const List<Color> successGradientColors = shopGradientColors;
  static const List<Color> warningGradientColors = staffGradientColors;
  static const List<Color> errorGradientColors = [
    Color(0xFFEF4444),
    Color(0xFFDC2626),
  ];
  static const List<Color> infoGradientColors = [
    Color(0xFF38BDF8),
    Color(0xFF0284C7),
  ];
}
