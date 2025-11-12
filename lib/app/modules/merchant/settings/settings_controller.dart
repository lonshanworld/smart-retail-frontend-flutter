import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/services/theme_service.dart';

class SettingsController extends GetxController {
  final ThemeService _themeService = Get.find<ThemeService>();

  late final Rx<ThemeMode> selectedThemeMode;

  @override
  void onInit() {
    super.onInit();
    selectedThemeMode = _themeService.theme.obs;
  }

  void changeTheme(ThemeMode? themeMode) {
    if (themeMode != null) {
      _themeService.switchTheme(themeMode);
      selectedThemeMode.value = themeMode;
    }
  }
}
