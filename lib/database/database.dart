import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show driftDatabase, DriftWebOptions;
import 'package:werewolf_narrator/database/name_cache.dart'
    show NameCache, NameCacheDao;

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

@DriftDatabase(tables: [NameCache], daos: [NameCacheDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_connectWithDriftFlutter());

  @override
  int get schemaVersion => 1;
}
