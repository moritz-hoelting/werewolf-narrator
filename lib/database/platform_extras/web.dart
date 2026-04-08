import 'package:collection/collection.dart';
import 'package:drift/wasm.dart' show WasmDatabase;
import 'package:drift_flutter/drift_flutter.dart'
    show DriftNativeOptions, DriftWebOptions;

Future<void> deleteDatabase({
  required String name,
  required DriftNativeOptions native,
  required DriftWebOptions web,
}) async {
  final probeResult = await WasmDatabase.probe(
    sqlite3Uri: web.sqlite3Wasm,
    driftWorkerUri: web.driftWorker,
    databaseName: name,
  );
  final db = probeResult.existingDatabases.firstWhereOrNull(
    (dbInfo) => dbInfo.$2 == name,
  );

  if (db != null) {
    await probeResult.deleteDatabase(db);
  }
}

Future<String> databaseLocation({
  required String name,
  required DriftNativeOptions native,
  required DriftWebOptions web,
}) async {
  final probeResult = await WasmDatabase.probe(
    sqlite3Uri: web.sqlite3Wasm,
    driftWorkerUri: web.driftWorker,
    databaseName: name,
  );
  final db = probeResult.existingDatabases.firstWhereOrNull(
    (dbInfo) => dbInfo.$2 == name,
  );

  if (db != null) {
    return db.$1.toString();
  } else {
    return 'Not found';
  }
}
