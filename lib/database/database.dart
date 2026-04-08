import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show DriftNativeOptions, DriftWebOptions, driftDatabase;
import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:werewolf_narrator/database/game.dart';
import 'package:werewolf_narrator/database/platform_extras/platform_extras.dart'
    as platform_extras;
import 'package:werewolf_narrator/database/player_names.dart'
    show PlayerNames, PlayerNamesDao;
import 'package:werewolf_narrator/database/settings.dart';
import 'package:werewolf_narrator/game/model/role.dart';

part 'database.g.dart';

const String databaseName = 'werewolf_narrator_db';
const DriftNativeOptions nativeOptions = DriftNativeOptions(
  databaseDirectory: getApplicationSupportDirectory,
);
final DriftWebOptions webOptions = DriftWebOptions(
  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
  driftWorker: Uri.parse('drift_worker.js'),
);

QueryExecutor _connectWithDriftFlutter() =>
    driftDatabase(name: databaseName, native: nativeOptions, web: webOptions);

@DriftDatabase(
  tables: [
    PlayerNames,
    Settings,
    Games,
    GamePlayers,
    GameRoles,
    CommandBatches,
    CommandEntries,
  ],
  daos: [PlayerNamesDao, SettingsDao, GamesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase.open(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      if (details.wasCreated) {
        await customStatement('PRAGMA foreign_keys = ON;');
      }
    },
  );
}

JsonTypeConverter2<Map<String, dynamic>, Uint8List, Object?> jsonMapConverter =
    TypeConverter.jsonb(
      fromJson: (json) => json as Map<String, dynamic>,
      toJson: (pref) => pref,
    );

class AppDatabaseHolder extends ChangeNotifier {
  AppDatabaseHolder._([this.executor]);

  static AppDatabaseHolder? _instance;

  factory AppDatabaseHolder([QueryExecutor? executor]) {
    _instance ??= AppDatabaseHolder._(executor);
    return _instance!;
  }

  final QueryExecutor? executor;
  AppDatabase? _database;

  AppDatabase get database {
    _database ??= _openDatabase();
    return _database!;
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  AppDatabase _openDatabase() =>
      AppDatabase.open(executor ?? _connectWithDriftFlutter());

  /// Recreates the entire database, no undo possible
  Future<void> recreateDatabase() async {
    await _database?.close();
    await platform_extras.deleteDatabase(
      name: databaseName,
      native: nativeOptions,
      web: webOptions,
    );

    _database = _openDatabase();

    notifyListeners();
  }

  static Future<String> databaseLocation() => platform_extras.databaseLocation(
    name: databaseName,
    native: nativeOptions,
    web: webOptions,
  );
}
