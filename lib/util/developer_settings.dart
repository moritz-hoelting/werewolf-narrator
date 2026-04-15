import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/database/settings.dart';
import 'package:werewolf_narrator/util/logging.dart' show DatabaseLog, logger;

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
  static const _fillVillagerRolesKey = 'dev:fillVillagerRoles';
  static const _logDatabaseQueriesKey = 'dev:logDatabaseQueries';

  bool _enabled = kDebugMode;
  bool _fillPlayerNames = true;
  bool _fillVillagerRoles = true;
  bool _logDatabaseQueries = false;

  bool get enabled => _enabled;
  bool get fillPlayerNames => _fillPlayerNames;
  bool get fillPlayerNamesEnabled => _enabled && _fillPlayerNames;
  bool get fillVillagerRoles => _fillVillagerRoles;
  bool get fillVillagerRolesEnabled => _enabled && _fillVillagerRoles;
  bool get logDatabaseQueries => _logDatabaseQueries;

  Future<void> _loadDeveloperSettings() async {
    _enabled = await _dao.getSettingBool(_enabledKey) ?? kDebugMode;
    _fillPlayerNames = await _dao.getSettingBool(_fillPlayerNamesKey) ?? true;
    _fillVillagerRoles =
        await _dao.getSettingBool(_fillVillagerRolesKey) ?? true;
    _logDatabaseQueries =
        await _dao.getSettingBool(_logDatabaseQueriesKey) ?? false;

    if (logDatabaseQueries) {
      logger.filter.disabledKeys.remove(DatabaseLog.keyValue);
    } else {
      logger.filter.disabledKeys.add(DatabaseLog.keyValue);
    }

    notifyListeners();
  }

  set enabled(bool enabled) {
    if (_enabled != enabled) {
      _enabled = enabled;
      logger.info('Setting developer mode to $enabled');
      notifyListeners();

      _dao.setSetting(_enabledKey, enabled, SettingsType.bool);
    }
  }

  set fillPlayerNames(bool fillPlayerNames) {
    if (_fillPlayerNames != fillPlayerNames) {
      _fillPlayerNames = fillPlayerNames;
      logger.info('Setting fill player names to $fillPlayerNames');
      notifyListeners();

      _dao.setSetting(_fillPlayerNamesKey, fillPlayerNames, SettingsType.bool);
    }
  }

  set fillVillagerRoles(bool fillVillagerRoles) {
    if (_fillVillagerRoles != fillVillagerRoles) {
      _fillVillagerRoles = fillVillagerRoles;
      logger.info('Setting fill villager roles to $fillVillagerRoles');
      notifyListeners();

      _dao.setSetting(
        _fillVillagerRolesKey,
        fillVillagerRoles,
        SettingsType.bool,
      );
    }
  }

  set logDatabaseQueries(bool logDatabaseQueries) {
    if (_logDatabaseQueries != logDatabaseQueries) {
      _logDatabaseQueries = logDatabaseQueries;
      if (logDatabaseQueries) {
        logger.filter.disabledKeys.remove(DatabaseLog.keyValue);
      } else {
        logger.filter.disabledKeys.add(DatabaseLog.keyValue);
      }
      logger.info('Setting log database queries to $logDatabaseQueries');
      notifyListeners();

      _dao.setSetting(
        _logDatabaseQueriesKey,
        logDatabaseQueries,
        SettingsType.bool,
      );
    }
  }
}
