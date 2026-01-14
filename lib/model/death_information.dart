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

enum DeathReason {
  werewolf,
  witch,
  lover,
  hunter,
  vote;

  String name(BuildContext context) {
    switch (this) {
      case DeathReason.werewolf:
        return 'Killed by Werewolves';
      case DeathReason.witch:
        return 'Poisoned by Witch';
      case DeathReason.lover:
        return 'Died for Lover';
      case DeathReason.hunter:
        return 'Shot by Hunter';
      case DeathReason.vote:
        return 'Voted Out';
    }
  }
}
