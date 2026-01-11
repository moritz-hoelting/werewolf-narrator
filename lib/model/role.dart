import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/death_reason.dart';
import 'package:werewolf_narrator/state/game.dart';

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

  RoleNightAction? get nightAction {
    switch (this) {
      case Role.witch:
        return RoleNightAction(maxSelection: 1);
      case Role.cupid:
        return RoleNightAction(
          maxSelection: 2,
          onConfirm: (selectedIndices, gameState) {
            assert(
              selectedIndices.length == 2,
              'Cupid must select exactly two players.',
            );
            selectedIndices.sort();
            gameState.setLovers(selectedIndices[0], selectedIndices[1]);
          },
        );
      case Role.werewolf:
        return RoleNightAction(
          maxSelection: 1,
          onConfirm: (playerIds, gameState) {
            assert(
              playerIds.length == 1,
              'Werewolves must select exactly one player to attack.',
            );
            gameState.markPlayerDead(playerIds[0], DeathReason.werewolf);
          },
        );
      default:
        return null;
    }
  }
}

class RoleNightAction {
  final int maxSelection;
  final PlayerSelectAction Function(int playerId, GameState gameState)?
  onPlayerSelected;
  final Function(List<int> playerIds, GameState gameState)? onConfirm;

  const RoleNightAction({
    required this.maxSelection,
    this.onPlayerSelected,
    this.onConfirm,
  });
}

class PlayerSelectAction {
  final bool? showRole;

  const PlayerSelectAction({this.showRole});
}
