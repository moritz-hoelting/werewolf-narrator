enum Role {
  villager,
  seer,
  witch,
  hunter,
  cupid,
  werewolf;

  String get name {
    switch (this) {
      case Role.villager:
        return 'Villager';
      case Role.seer:
        return 'Seer';
      case Role.witch:
        return 'Witch';
      case Role.hunter:
        return 'Hunter';
      case Role.cupid:
        return 'Cupid';
      case Role.werewolf:
        return 'Werewolf';
    }
  }

  bool get isUnique {
    switch (this) {
      case Role.villager:
      case Role.werewolf:
        return false;
      case Role.seer:
      case Role.witch:
      case Role.hunter:
      case Role.cupid:
        return true;
    }
  }
}
