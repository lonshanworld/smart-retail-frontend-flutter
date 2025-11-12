import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/services/theme_service.dart';

class ShopSettingsController extends GetxController {
  final ThemeService _themeService = Get.find<ThemeService>();

  // CORRECTED: Expose the current theme state correctly
  RxBool get isDarkMode => (_themeService.theme == ThemeMode.dark).obs;

  // CORRECTED: Method to toggle the theme
  void toggleTheme(bool isDark) {
    _themeService.switchTheme(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
