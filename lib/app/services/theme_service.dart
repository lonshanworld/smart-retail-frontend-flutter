import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeService extends GetxService {
  // Force light mode only - dark mode removed
  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;
  ThemeMode get theme => ThemeMode.light;

  Future<ThemeService> init() async {
    Get.changeThemeMode(ThemeMode.light);
    return this;
  }

  void switchTheme(ThemeMode themeMode) {
    // Always use light mode regardless of parameter
    _themeMode.value = ThemeMode.light;
    Get.changeThemeMode(ThemeMode.light);
  }
}
