import 'package:flutter/material.dart';

enum Role {
  villager(isUnique: false),
  seer(isUnique: true),
  witch(isUnique: true),
  hunter(isUnique: true),
  cupid(isUnique: true),
  werewolf(isUnique: false);

  const Role({required this.isUnique});

  final bool isUnique;

  String name(BuildContext _) {
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
}
