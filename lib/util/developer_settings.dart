import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/database/settings.dart';

final class DeveloperSettings extends ChangeNotifier {
  static late final DeveloperSettings instance;

  final AppDatabaseHolder _holder;

  DeveloperSettings._(this._holder);

  static Future<void> init(AppDatabaseHolder db) async {
    instance = DeveloperSettings._(db);
    await instance._loadDeveloperSettings();
  }

  SettingsDao get _dao => _holder.database.settingsDao;

  // Keys
  static const _enabledKey = 'dev:enabled';
  static const _fillPlayerNamesKey = 'dev:fillPlayerNames';

  bool _enabled = kDebugMode;
  bool _fillPlayerNames = true;

  bool get enabled => _enabled;
  bool get fillPlayerNames => _fillPlayerNames;
  bool get fillPlayerNamesEnabled => _enabled && _fillPlayerNames;

  Future<void> _loadDeveloperSettings() async {
    _enabled = await _dao.getSettingBool(_enabledKey) ?? kDebugMode;
    _fillPlayerNames = await _dao.getSettingBool(_fillPlayerNamesKey) ?? true;
    notifyListeners();
  }

  set enabled(bool enabled) {
    if (_enabled != enabled) {
      _enabled = enabled;
      notifyListeners();
      _dao.setSetting(_enabledKey, enabled, SettingsType.bool);
    }
  }

  set fillPlayerNames(bool fillPlayerNames) {
    if (_fillPlayerNames != fillPlayerNames) {
      _fillPlayerNames = fillPlayerNames;
      notifyListeners();
      _dao.setSetting(_fillPlayerNamesKey, fillPlayerNames, SettingsType.bool);
    }
  }
}
