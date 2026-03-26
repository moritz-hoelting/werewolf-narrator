import 'dart:collection';

import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/big_bad_wolf.dart'
    show BigBadWolfRole;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

@RegisterRole()
class DoctorRole extends Role {
  DoctorRole._({required RoleConfiguration config, required super.playerIndex})
    : protectPlayerCooldown = config[protectPlayerCooldownOptionKey];
  static final RoleType<DoctorRole> type = RoleType<DoctorRole>();
  @override
  RoleType<DoctorRole> get objectType => type;

  static const String protectPlayerCooldownOptionKey = "protectPlayerCooldown";

  final int protectPlayerCooldown;

  Queue<int> playersInCooldown = Queue();
  int? protectionTarget;

  static void registerRole() {
    RoleManager.registerRole<DoctorRole>(
      type,
      RegisterRoleInformation(
        constructor: DoctorRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_doctor_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_doctor_checkInstruction(count: count),
        validRoleCounts: const [1],
        options: IList([
          IntOption(
            id: protectPlayerCooldownOptionKey,
            label: (context) => AppLocalizations.of(
              context,
            ).role_doctor_option_protectPlayerCooldown_label,
            description: (context) => AppLocalizations.of(
              context,
            ).role_doctor_option_protectPlayerCooldown_description,
            defaultValue: 0,
            min: 0,
          ),
        ]),
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 5,
        ),
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_doctor_name;

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(AssignDoctorCommand(playerIndex: playerIndex));
  }

  void addToCooldownList(int playerIndex) {
    playersInCooldown.add(playerIndex);
    while (playersInCooldown.length > protectPlayerCooldown) {
      playersInCooldown.removeFirst();
    }
  }
}

class AssignDoctorCommand implements GameCommand {
  AssignDoctorCommand({required this.playerIndex});

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      DoctorRole.type,
      (gameState, onComplete) => nightActionScreen(gameState, onComplete),
      players: {playerIndex},
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      before: IList([WitchRole.type, BigBadWolfRole.type, WerewolvesTeam.type]),
    );

    gameData.dawnHooks.add((gameState, dayCount) {
      gameState.apply(
        SetDoctorProtectionTargetCommand(
          playerIndex: playerIndex,
          targetPlayerIndex: null,
        ),
      );
    });

    gameData.deathHooks.add(
      (gameState, deadPlayerIndex, reason) =>
          gameState.isNight &&
          (gameState.players[playerIndex].role as DoctorRole)
                  .protectionTarget ==
              deadPlayerIndex,
    );
  }

  @override
  // TODO: implement canBeUndone
  bool get canBeUndone => throw UnimplementedError();

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
  }

  WidgetBuilder nightActionScreen(
    GameState gameState,
    VoidCallback onComplete,
  ) => (BuildContext context) {
    return ActionScreen(
      key: UniqueKey(),
      actionIdentifier: DoctorRole.type,
      appBarTitle: Text(DoctorRole._name(context)),
      selectionCount: 1,
      currentActorIndices: ISet({playerIndex}),
      disabledPlayerIndices: (gameState.players[playerIndex].role as DoctorRole)
          .playersInCooldown
          .toISet(),
      instruction: Text(
        AppLocalizations.of(context).role_doctor_nightAction_instruction,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onConfirm: (playerIds, gameState) {
        final protectPlayerIndex = playerIds.singleOrNull;
        if (protectPlayerIndex != null) {
          gameState.apply(
            SetDoctorProtectionTargetCommand(
              playerIndex: playerIndex,
              targetPlayerIndex: protectPlayerIndex,
            ),
          );
        }
        onComplete();
      },
    );
  };
}

class SetDoctorProtectionTargetCommand implements GameCommand {
  const SetDoctorProtectionTargetCommand({
    required this.playerIndex,
    required this.targetPlayerIndex,
  });

  final int playerIndex;
  final int? targetPlayerIndex;

  @override
  void apply(GameData gameData) {
    final doctorRole = gameData.players[playerIndex].role as DoctorRole;
    doctorRole.protectionTarget = targetPlayerIndex;
    if (targetPlayerIndex != null) {
      doctorRole.addToCooldownList(targetPlayerIndex!);
    }
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    throw UnimplementedError();
  }
}
