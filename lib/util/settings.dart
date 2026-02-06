import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferencesAsync;

final class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();

  AppSettings._() {
    _loadSettings();
  }

  // Load preferences asynchronously
  Future<void> _loadSettings() async {
    final prefs = SharedPreferencesAsync();
    _themeMode = await _getSavedThemeMode(prefs) ?? ThemeMode.system;
    _dynamicGameTheme = await prefs.getBool(_dynamicGameThemeKey) ?? true;
    _locale = await _getSavedLocale(prefs);
    notifyListeners();
  }

  // Preferences keys
  static const _themeModeKey = 'themeMode';
  static const _dynamicGameThemeKey = 'dynamicGameTheme';
  static const _localeKey = 'locale';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      _saveThemeMode(mode);
    }
  }

  bool _dynamicGameTheme = true;
  bool get dynamicGameTheme => _dynamicGameTheme;
  set dynamicGameTheme(bool value) {
    if (_dynamicGameTheme != value) {
      _dynamicGameTheme = value;
      notifyListeners();
      _saveDynamicGameTheme(value);
    }
  }

  Locale? _locale;
  Locale? get locale => _locale;
  set locale(Locale? newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
      _saveLocale(newLocale);
    }
  }

  Future<ThemeMode?> _getSavedThemeMode(SharedPreferencesAsync prefs) async {
    final index = await prefs.getInt(_themeModeKey);
    if (index != null && index >= 0 && index < ThemeMode.values.length) {
      return ThemeMode.values[index];
    }
    return ThemeMode.system;
  }

  Future<Locale?> _getSavedLocale(SharedPreferencesAsync prefs) async {
    final localeString = await prefs.getString(_localeKey);
    if (localeString != null) {
      final parts = localeString.split('_');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      } else if (parts.length == 1) {
        return Locale(parts[0]);
      }
    }
    return null;
  }

  void _saveThemeMode(ThemeMode mode, [SharedPreferencesAsync? prefs]) async {
    prefs ??= SharedPreferencesAsync();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  void _saveDynamicGameTheme(
    bool value, [
    SharedPreferencesAsync? prefs,
  ]) async {
    prefs ??= SharedPreferencesAsync();
    await prefs.setBool(_dynamicGameThemeKey, value);
  }

  void _saveLocale(Locale? locale, [SharedPreferencesAsync? prefs]) async {
    prefs ??= SharedPreferencesAsync();
    if (locale != null) {
      final localeString = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      await prefs.setString(_localeKey, localeString);
    } else {
      await prefs.remove(_localeKey);
    }
  }
}
