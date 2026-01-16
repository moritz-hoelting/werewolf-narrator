import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

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
    final localizations = AppLocalizations.of(context)!;
    switch (this) {
      case DeathReason.werewolf:
        return localizations.deathReason_werewolf;
      case DeathReason.witch:
        return localizations.deathReason_witch;
      case DeathReason.lover:
        return localizations.deathReason_lover;
      case DeathReason.hunter:
        return localizations.deathReason_hunter;
      case DeathReason.vote:
        return localizations.deathReason_villageVote;
    }
  }
}
