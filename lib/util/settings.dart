import 'package:flutter/material.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/database/settings.dart';

final class AppSettings extends ChangeNotifier {
  static late final AppSettings instance;

  final AppDatabaseHolder _holder;

  AppSettings._(this._holder);

  static Future<void> init(AppDatabaseHolder db) async {
    instance = AppSettings._(db);
    await instance._loadSettings();
  }

  SettingsDao get _dao => _holder.database.settingsDao;

  // Keys
  static const _themeModeKey = 'themeMode';
  static const _dynamicGameThemeKey = 'dynamicGameTheme';
  static const _localeKey = 'locale';

  ThemeMode _themeMode = ThemeMode.system;
  bool _dynamicGameTheme = true;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  bool get dynamicGameTheme => _dynamicGameTheme;
  Locale? get locale => _locale;

  Future<void> _loadSettings() async {
    _themeMode =
        await _dao.getSettingEnum(_themeModeKey, ThemeMode.values) ??
        ThemeMode.system;

    _dynamicGameTheme = await _dao.getSettingBool(_dynamicGameThemeKey) ?? true;

    final localeString = await _dao.getSettingString(_localeKey);

    _locale = _parseLocale(localeString);

    notifyListeners();
  }

  set themeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();

      _dao.setSetting(_themeModeKey, mode.name, SettingsType.enumType);
    }
  }

  set dynamicGameTheme(bool value) {
    if (_dynamicGameTheme != value) {
      _dynamicGameTheme = value;
      notifyListeners();

      _dao.setSetting(_dynamicGameThemeKey, value, SettingsType.bool);
    }
  }

  set locale(Locale? newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();

      if (newLocale != null) {
        final localeString = newLocale.countryCode != null
            ? '${newLocale.languageCode}_${newLocale.countryCode}'
            : newLocale.languageCode;

        _dao.setSetting(_localeKey, localeString, SettingsType.string);
      } else {
        _dao.setSetting(_localeKey, '', SettingsType.string);
      }
    }
  }

  Locale? _parseLocale(String? localeString) {
    if (localeString == null || localeString.isEmpty) return null;

    final parts = localeString.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else if (parts.length == 1) {
      return Locale(parts[0]);
    }
    return null;
  }
}
