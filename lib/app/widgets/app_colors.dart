import 'package:flutter/material.dart';

/// Centralized color scheme for the app
class AppColors {
  // Primary colors
  static const MaterialColor primary = Colors.blue;
  static const MaterialColor secondary = Colors.purple;
  
  // Role-based colors
  static const MaterialColor merchant = Colors.blue;
  static const MaterialColor shop = Colors.green;
  static const MaterialColor staff = Colors.orange;
  static const MaterialColor admin = Colors.indigo;
  
  // Status colors
  static const MaterialColor success = Colors.green;
  static const MaterialColor warning = Colors.orange;
  static const MaterialColor error = Colors.red;
  static const MaterialColor info = Colors.blue;
  
  // Gradient combinations
  static const List<Color> primaryGradientColors = [Color(0xFF667eea), Color(0xFF764ba2)];
  static const List<Color> successGradientColors = [Color(0xFF11998e), Color(0xFF38ef7d)];
  static const List<Color> warningGradientColors = [Color(0xFFf46b45), Color(0xFFeea849)];
  static const List<Color> errorGradientColors = [Color(0xFFeb3349), Color(0xFFF45c43)];
  static const List<Color> infoGradientColors = [Color(0xFF4facfe), Color(0xFF00f2fe)];
  
  // Role-based gradient colors
  static const List<Color> merchantGradientColors = [Color(0xFF667eea), Color(0xFF764ba2)];
  static const List<Color> shopGradientColors = [Color(0xFF11998e), Color(0xFF38ef7d)];
  static const List<Color> staffGradientColors = [Color(0xFFf46b45), Color(0xFFeea849)];
  static const List<Color> adminGradientColors = [Color(0xFF6a11cb), Color(0xFF2575fc)];
  
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
  static final Color backgroundGrey = Colors.grey.shade50;
  static const Color cardBackground = Colors.white;
  
  // Text colors
  static final Color textPrimary = Colors.grey.shade900;
  static final Color textSecondary = Colors.grey.shade600;
  static final Color textHint = Colors.grey.shade400;
}
