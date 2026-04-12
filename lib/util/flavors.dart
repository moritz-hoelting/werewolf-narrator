import 'package:flutter/services.dart' as flutter_services;

const String prodAppFlavorName = 'prod';

bool get isProdAppFlavor =>
    flutter_services.appFlavor == null ||
    flutter_services.appFlavor!.isEmpty ||
    flutter_services.appFlavor == prodAppFlavorName;

String get appFlavor => isProdAppFlavor
    ? prodAppFlavorName
    : flutter_services.appFlavor ?? 'unknown';
