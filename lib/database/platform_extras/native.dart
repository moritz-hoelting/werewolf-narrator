import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

Future<void> deleteDatabase({
  required String name,
  required DriftNativeOptions native,
  required DriftWebOptions web,
}) async {
  final file = await _databaseFile(name, native);

  if (await file.exists()) {
    await file.delete();
  }
}

Future<String> databaseLocation({
  required String name,
  required DriftNativeOptions native,
  required DriftWebOptions web,
}) async {
  final file = await _databaseFile(name, native);
  return file.path;
}

/// Copied from drift_flutter.dart
Future<File> _databaseFile(String name, DriftNativeOptions native) async {
  if (native.databasePath case final lookupPath?) {
    return File(await lookupPath());
  } else {
    final resolvedDirectory =
        await (native.databaseDirectory ?? getApplicationDocumentsDirectory)();

    return File(
      p.join(switch (resolvedDirectory) {
        Directory(:final path) => path,
        final String path => path,
        final other => throw ArgumentError.value(
          other,
          'other',
          'databaseDirectory on DriftNativeOptions must resolve to a '
              'directory or a path as string.',
        ),
      }, '$name.sqlite'),
    );
  }
}
