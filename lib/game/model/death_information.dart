import 'package:flutter/material.dart';

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
}

abstract interface class DeathReason {
  String deathReasonDescription(BuildContext context);
}
