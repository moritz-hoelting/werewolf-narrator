import 'package:drift_flutter/drift_flutter.dart'
    show DriftNativeOptions, DriftWebOptions;

Future<void> deleteDatabase({
  required String name,
  required DriftNativeOptions native,
  required DriftWebOptions web,
}) async {
  throw UnsupportedError(
    'deleteDatabase() is not implemented on this platform because neither '
    '`dart:ffi` nor `dart:js_interop` are available.',
  );
}

Future<String> databaseLocation({
  required String name,
  required DriftNativeOptions native,
  required DriftWebOptions web,
}) async {
  throw UnsupportedError(
    'databaseLocation() is not implemented on this platform because neither '
    '`dart:ffi` nor `dart:js_interop` are available.',
  );
}
