import 'package:flutter/services.dart' as flutter_services;

const String _prodAppFlavorName = 'prod';

const String _appFlavor = String.fromEnvironment(
  'FLAVOR',
  defaultValue: flutter_services.appFlavor ?? _prodAppFlavorName,
);

const AppFlavor appFlavor = _appFlavor == _prodAppFlavorName
    ? AppFlavor.prod
    : _appFlavor == 'dev'
    ? AppFlavor.dev
    : _appFlavor == 'staging'
    ? AppFlavor.staging
    // Fallback to prod if the flavor is unrecognized
    : AppFlavor.prod;

enum AppFlavor {
  prod,
  dev,
  staging;

  bool get isProd => this == AppFlavor.prod;

  @override
  String toString() {
    switch (this) {
      case AppFlavor.prod:
        return 'prod';
      case AppFlavor.dev:
        return 'dev';
      case AppFlavor.staging:
        return 'staging';
    }
  }
}
