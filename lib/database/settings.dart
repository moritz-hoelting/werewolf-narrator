import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart';
import 'package:werewolf_narrator/database/database.dart';

part 'settings.g.dart';

class Settings extends Table {
  TextColumn get name => text().withLength(min: 1)();
  AnyColumn get value => sqliteAny()();
  TextColumn get type => textEnum<SettingsType>()();

  @override
  Set<Column> get primaryKey => {name};

  @override
  bool get isStrict => true;
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Future<void> setSetting(String name, dynamic value, SettingsType type) async {
    await into(settings).insert(
      SettingsCompanion.insert(name: name, value: DriftAny(value), type: type),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<Setting?> _getSettingEntry(String name) async {
    final setting = await (select(
      settings,
    )..where((s) => s.name.equals(name))).getSingleOrNull();
    return setting;
  }

  Future<bool?> getSettingBool(String name) async {
    final setting = await _getSettingEntry(name);
    if (setting == null) {
      return null;
    }
    if (setting.type != SettingsType.bool) {
      throw Exception(
        'Setting with name $name is expected to be of type bool, but is ${setting.type}',
      );
    }
    return setting.value.readAs<bool>(DriftSqlType.bool, typeMapping);
  }

  Future<int?> getSettingInt(String name) async {
    final setting = await _getSettingEntry(name);
    if (setting == null) {
      return null;
    }
    if (setting.type != SettingsType.int) {
      throw Exception(
        'Setting with name $name is expected to be of type int, but is ${setting.type}',
      );
    }
    return setting.value.readAs<int>(DriftSqlType.int, typeMapping);
  }

  Future<String?> getSettingString(String name) async {
    final setting = await _getSettingEntry(name);
    if (setting == null) {
      return null;
    }
    if (setting.type != SettingsType.string) {
      throw Exception(
        'Setting with name $name is expected to be of type string, but is ${setting.type}',
      );
    }
    return setting.value.readAs<String>(DriftSqlType.string, typeMapping);
  }

  Future<T?> getSettingEnum<T extends Enum>(
    String name,
    List<T> enumValues,
  ) async {
    final setting = await _getSettingEntry(name);
    if (setting == null) {
      return null;
    }
    if (setting.type != SettingsType.enumType) {
      throw Exception(
        'Setting with name $name is expected to be of type enumType, but is ${setting.type}',
      );
    }
    final enumName = setting.value.readAs<String>(
      DriftSqlType.string,
      typeMapping,
    );
    final index = enumValues.indexWhere((e) => e.name == enumName);
    if (index < 0 || index >= enumValues.length) {
      throw Exception('Invalid enum index $index for setting with name $name');
    }
    return enumValues[index];
  }
}

enum SettingsType { bool, int, string, enumType }
