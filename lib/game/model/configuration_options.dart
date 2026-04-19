import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart' show BuildContext;

typedef RoleConfiguration = Map<String, dynamic>;

typedef GameConfiguration = IMap<String, dynamic>;

sealed class ConfigurationOption<T> {
  final String id;
  final String Function(BuildContext context) label;
  final String Function(BuildContext context) description;
  final T defaultValue;

  const ConfigurationOption({
    required this.id,
    required this.label,
    required this.description,
    required this.defaultValue,
  });

  T read(Map<String, dynamic> config) {
    if (config.containsKey(id)) {
      return config[id] as T;
    } else {
      return defaultValue;
    }
  }
}

class BoolOption extends ConfigurationOption<bool> {
  const BoolOption({
    required super.id,
    required super.label,
    required super.description,
    super.defaultValue = false,
  });
}

class IntOption extends ConfigurationOption<int> {
  final int? min;
  final int? max;

  const IntOption({
    required super.id,
    required super.label,
    required super.description,
    required super.defaultValue,
    this.min,
    this.max,
  });
}
