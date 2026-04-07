import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show DriftWebOptions, driftDatabase;
import 'package:werewolf_narrator/database/game.dart';
import 'package:werewolf_narrator/database/player_names.dart'
    show PlayerNames, PlayerNamesDao;
import 'package:werewolf_narrator/database/settings.dart';
import 'package:werewolf_narrator/game/model/role.dart';

part 'database.g.dart';

QueryExecutor _connectWithDriftFlutter() => driftDatabase(
  name: 'werewolf_narrator_db',
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  ),
);

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
  AppDatabase.open([QueryExecutor? executor])
    : super(executor ?? _connectWithDriftFlutter());
  static AppDatabase? instance;

  factory AppDatabase([QueryExecutor? executor]) {
    instance ??= AppDatabase.open(executor);
    return instance!;
  }

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
