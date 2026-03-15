import 'package:flutter/material.dart';

typedef RoleConfiguration = Map<String, dynamic>;

sealed class RoleOption<T> {
  final String id;
  final String Function(BuildContext context) label;
  final String Function(BuildContext context) description;
  final T defaultValue;

  const RoleOption({
    required this.id,
    required this.label,
    required this.description,
    required this.defaultValue,
  });
}

class BoolOption extends RoleOption<bool> {
  const BoolOption({
    required super.id,
    required super.label,
    required super.description,
    super.defaultValue = false,
  });
}

class IntOption extends RoleOption<int> {
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
