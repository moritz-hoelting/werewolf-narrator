import 'package:flutter/material.dart';

enum DeathReason {
  werewolf,
  witch,
  lover,
  vote;

  String name(BuildContext context) {
    switch (this) {
      case DeathReason.werewolf:
        return 'Killed by Werewolves';
      case DeathReason.witch:
        return 'Poisoned by Witch';
      case DeathReason.lover:
        return 'Died for Lover';
      case DeathReason.vote:
        return 'Voted Out';
    }
  }
}
