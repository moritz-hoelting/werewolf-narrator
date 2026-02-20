import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferencesAsync;

final class DeveloperSettings extends ChangeNotifier {
  static final DeveloperSettings instance = DeveloperSettings._();

  DeveloperSettings._() {
    _loadDeveloperSettings();
  }

  // Load preferences asynchronously
  Future<void> _loadDeveloperSettings() async {
    final prefs = SharedPreferencesAsync();
    _enabled = await _getSavedEnabled(prefs) ?? kDebugMode;
    _fillPlayerNames = await _getSavedFillPlayerNames(prefs) ?? true;
    notifyListeners();
  }

  // Preferences keys
  static const _enabledKey = 'dev:enabled';
  static const _fillPlayerNamesKey = 'dev:fillPlayerNames';

  bool _enabled = kDebugMode;
  bool get enabled => _enabled;
  set enabled(bool enabled) {
    if (_enabled != enabled) {
      _enabled = enabled;
      notifyListeners();
      _saveEnabled(enabled);
    }
  }

  bool _fillPlayerNames = true;
  bool get fillPlayerNames => _fillPlayerNames;
  bool get fillPlayerNamesEnabled => _enabled && _fillPlayerNames;
  set fillPlayerNames(bool fillPlayerNames) {
    if (_fillPlayerNames != fillPlayerNames) {
      _fillPlayerNames = fillPlayerNames;
      notifyListeners();
      _saveFillPlayerNames(fillPlayerNames);
    }
  }

  Future<bool?> _getSavedEnabled(SharedPreferencesAsync prefs) async {
    return await prefs.getBool(_enabledKey);
  }

  Future<bool?> _getSavedFillPlayerNames(SharedPreferencesAsync prefs) async {
    return await prefs.getBool(_fillPlayerNamesKey);
  }

  void _saveEnabled(bool enabled, [SharedPreferencesAsync? prefs]) async {
    prefs ??= SharedPreferencesAsync();
    await prefs.setBool(_enabledKey, enabled);
  }

  void _saveFillPlayerNames(
    bool fillPlayerNames, [
    SharedPreferencesAsync? prefs,
  ]) async {
    prefs ??= SharedPreferencesAsync();
    await prefs.setBool(_fillPlayerNamesKey, fillPlayerNames);
  }
}
