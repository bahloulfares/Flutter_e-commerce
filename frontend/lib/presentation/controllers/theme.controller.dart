import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atelier7/utils/constants.dart';

class ThemeController extends GetxController {
  final RxBool isDarkMode = false.obs;

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(StorageKeys.theme) ?? 'light';
    isDarkMode.value = savedTheme == 'dark';
  }

  Future<void> setDarkMode(bool isDark) async {
    isDarkMode.value = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.theme, isDark ? 'dark' : 'light');
  }
}
