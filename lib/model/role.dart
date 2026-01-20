import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/views/game/roles/hunter_screen.dart';

enum Role {
  villager(isUnique: false),
  seer(isUnique: true),
  witch(isUnique: true),
  hunter(isUnique: true),
  cupid(isUnique: true),
  littleGirl(isUnique: true),
  thief(isUnique: true),
  werewolf(isUnique: false);

  const Role({required this.isUnique});

  final bool isUnique;

  String name(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (this) {
      case Role.villager:
        return localizations.role_villager_name;
      case Role.seer:
        return localizations.role_seer_name;
      case Role.witch:
        return localizations.role_witch_name;
      case Role.hunter:
        return localizations.role_hunter_name;
      case Role.cupid:
        return localizations.role_cupid_name;
      case Role.littleGirl:
        return localizations.role_littleGirl_name;
      case Role.thief:
        return localizations.role_thief_name;
      case Role.werewolf:
        return localizations.role_werewolf_name;
    }
  }

  String description(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (this) {
      case Role.villager:
        return localizations.role_villager_description;
      case Role.seer:
        return localizations.role_seer_description;
      case Role.witch:
        return localizations.role_witch_description;
      case Role.hunter:
        return localizations.role_hunter_description;
      case Role.cupid:
        return localizations.role_cupid_description;
      case Role.littleGirl:
        return localizations.role_littleGirl_description;
      case Role.thief:
        return localizations.role_thief_description;
      case Role.werewolf:
        return localizations.role_werewolf_description;
    }
  }

  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context)!;
    switch (this) {
      case Role.villager:
        throw UnimplementedError(
          'Role $this does not have a check role instruction.',
        );
      case Role.seer:
        return localizations.screen_checkRoles_instruction_seer(count);
      case Role.witch:
        return localizations.screen_checkRoles_instruction_witch(count);
      case Role.hunter:
        return localizations.screen_checkRoles_instruction_hunter(count);
      case Role.cupid:
        return localizations.screen_checkRoles_instruction_cupid(count);
      case Role.littleGirl:
        return localizations.screen_checkRoles_instruction_littleGirl(count);
      case Role.thief:
        return localizations.screen_checkRoles_instruction_thief(count);
      case Role.werewolf:
        return localizations.screen_checkRoles_instruction_werewolf(count);
    }
  }

  String selectActionInstruction(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (this) {
      case Role.witch:
        return localizations.screen_roleAction_instruction_witch;
      case Role.cupid:
        return localizations.screen_roleAction_instruction_cupid;
      case Role.werewolf:
        return localizations.screen_roleAction_instruction_werewolf;
      case Role.seer:
        return localizations.screen_roleAction_instruction_seer;
      case Role.hunter:
        return localizations.screen_roleAction_instruction_hunter;
      default:
        throw UnimplementedError(
          'Role $this does not have a night action instruction.',
        );
    }
  }

  RoleNightAction? get nightAction {
    switch (this) {
      case Role.witch:
        return RoleNightAction(selectionCount: 1);
      case Role.cupid:
        return RoleNightAction(
          selectionCount: 2,
          allowSelfSelect: true,
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
          selectionCount: 1,
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

  Team get team {
    switch (this) {
      case Role.werewolf:
        return Team.werewolves;
      case Role.villager:
      case Role.seer:
      case Role.witch:
      case Role.hunter:
      case Role.cupid:
      case Role.littleGirl:
      case Role.thief:
        return Team.village;
    }
  }

  bool get hasDeathScreen {
    switch (this) {
      case Role.hunter:
        return true;
      default:
        return false;
    }
  }

  Widget Function(VoidCallback onPhaseComplete)? getDeathScreen(
    int playerIndex,
  ) {
    switch (this) {
      case Role.hunter:
        return (onPhaseComplete) => HunterScreen(
          playerIndex: playerIndex,
          onPhaseComplete: onPhaseComplete,
        );
      default:
        return null;
    }
  }
}

class RoleNightAction {
  final int selectionCount;
  final bool allowSelfSelect;
  final void Function(List<int> playerIds, GameState gameState)? onConfirm;

  const RoleNightAction({
    required this.selectionCount,
    this.onConfirm,
    this.allowSelfSelect = false,
  });
}

class PlayerSelectAction {
  final bool? showRole;

  const PlayerSelectAction({this.showRole});
}
