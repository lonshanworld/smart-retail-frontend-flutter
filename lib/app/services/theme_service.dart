import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  static const _themeKey = 'theme_mode';

  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  ThemeMode get theme => _themeMode.value;

  Future<ThemeService> init() async {
    await _loadThemeFromStorage();
    return this;
  }

  Future<void> _loadThemeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? ThemeMode.system.toString();
    _themeMode.value = ThemeMode.values.firstWhere(
      (e) => e.toString() == themeString,
      orElse: () => ThemeMode.system,
    );
    Get.changeThemeMode(_themeMode.value);
  }

  Future<void> _saveThemeToStorage(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode.toString());
  }

  void switchTheme(ThemeMode themeMode) {
    _themeMode.value = themeMode;
    Get.changeThemeMode(themeMode);
    _saveThemeToStorage(themeMode);
  }
}
