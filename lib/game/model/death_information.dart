import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';

part 'death_information.mapper.dart';

/// Information about a player's death.
class DeathInformation {
  /// The reason for the death.
  final DeathReason reason;

  /// The day on which the death occurred.
  final int day;

  /// Whether the death occurred at night.
  final bool atNight;

  const DeathInformation({
    required this.reason,
    required this.day,
    required this.atNight,
  });

  @override
  String toString() {
    return 'DeathInformation(reason: $reason, day: $day, atNight: $atNight)';
  }
}

@MappableClass(discriminatorKey: 'type')
abstract interface class DeathReason with DeathReasonMappable {
  /// A description of the death reason, used for the death screen.
  String deathReasonDescription(BuildContext context);

  /// The players responsible for the death.
  ISet<int> get responsiblePlayerIndices;
}
