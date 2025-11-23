import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StaffSettingsController extends GetxController {
  // ADDED: Observable to hold the currently selected theme mode.
  final Rx<ThemeMode> selectedThemeMode =
      (Get.isDarkMode ? ThemeMode.dark : ThemeMode.light).obs;

  void changeTheme(ThemeMode? themeMode) {
    if (themeMode == null) return;
    Get.changeThemeMode(themeMode);
    selectedThemeMode.value = themeMode;
  }
}
