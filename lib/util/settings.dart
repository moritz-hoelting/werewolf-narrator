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
    _nameCache = await prefs.getStringList(_nameCacheKey) ?? [];
    notifyListeners();
  }

  // Preferences keys
  static const _themeModeKey = 'themeMode';
  static const _dynamicGameThemeKey = 'dynamicGameTheme';
  static const _localeKey = 'locale';
  static const _nameCacheKey = 'nameCache';
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

  List<String> _nameCache = [];
  List<String> get nameCache => _nameCache;
  set nameCache(List<String> newCache) {
    _nameCache = newCache;
    notifyListeners();
    _saveNameCache(newCache);
  }

  void addNamesToCache(List<String> names) {
    for (final name in names) {
      if (!_nameCache.contains(name)) {
        _nameCache = [..._nameCache, name];
      }
    }
    notifyListeners();
    _saveNameCache(_nameCache);
  }

  void deleteNameFromCache(String name) {
    _nameCache = _nameCache.where((n) => n != name).toList();
    notifyListeners();
    _saveNameCache(_nameCache);
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

  void _saveNameCache(
    List<String> nameCache, [
    SharedPreferencesAsync? prefs,
  ]) async {
    prefs ??= SharedPreferencesAsync();
    await prefs.setStringList(_nameCacheKey, nameCache);
  }
}
