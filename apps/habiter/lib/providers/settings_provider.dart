import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

/// Central provider for app-wide settings: theme and locale.
/// Persists settings to SharedPreferences for restart survival.
class SettingsProvider extends ChangeNotifier {
  static const _themeModeKey = 'settings_theme_mode';
  static const _localeKey = 'settings_locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('de');
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isLoaded => _isLoaded;

  /// Load settings from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString != null) {
      _themeMode = _themeModeFromString(themeModeString);
    }

    // Load locale
    final localeString = prefs.getString(_localeKey);
    if (localeString != null) {
      _locale = Locale(localeString);
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Set theme mode and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  /// Set locale and persist
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Convert ThemePreference (from habit.dart) to ThemeMode
  ThemeMode themeModeFromPreference(ThemePreference pref) {
    switch (pref) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return ThemeMode.system;
    }
  }

  /// Convert ThemeMode to ThemePreference (for settings screen compatibility)
  ThemePreference preferenceFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return ThemePreference.light;
      case ThemeMode.dark:
        return ThemePreference.dark;
      case ThemeMode.system:
        return ThemePreference.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
