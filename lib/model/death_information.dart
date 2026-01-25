import 'package:flutter/material.dart';

class DeathInformation {
  final DeathReason reason;
  final int day;
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
