import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show driftDatabase, DriftWebOptions;
import 'package:werewolf_narrator/database/name_cache.dart'
    show NameCache, NameCacheDao;
import 'package:werewolf_narrator/database/settings.dart';

part 'database.g.dart';

QueryExecutor _connectWithDriftFlutter() {
  return driftDatabase(
    name: 'werewolf_narrator_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

@DriftDatabase(tables: [NameCache, Settings], daos: [NameCacheDao, SettingsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_connectWithDriftFlutter());
  static final AppDatabase instance = AppDatabase._();

  factory AppDatabase() => instance;

  @override
  int get schemaVersion => 1;
}
