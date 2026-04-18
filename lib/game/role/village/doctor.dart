import 'dart:collection';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/death_information.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/big_bad_wolf.dart'
    show BigBadWolfRole;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'doctor.mapper.dart';

@RegisterRole()
class DoctorRole extends Role {
  DoctorRole._({required RoleConfiguration config, required super.playerIndex})
    : protectPlayerCooldown = config[protectPlayerCooldownOptionKey];
  static final RoleType type = RoleType.of<DoctorRole>();
  @override
  RoleType get roleType => type;

  static const String protectPlayerCooldownOptionKey = 'protectPlayerCooldown';

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
        chooseRolesInformation: const ChooseRolesInformation(
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
}

@MappableClass(discriminatorValue: 'assignDoctor')
class AssignDoctorCommand
    with AssignDoctorCommandMappable
    implements GameCommand {
  const AssignDoctorCommand({required this.playerIndex});

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      DoctorRole.type,
      (gameState, onComplete) => nightActionScreen(gameState, onComplete),
      players: {playerIndex},
      conditioned: (gameState) => gameState.players[playerIndex].isAlive,
      before: ISet({WitchRole.type, BigBadWolfRole.type, WerewolvesTeam.type}),
    );

    gameData.dawnHooks.add(dawnHook);
    gameData.deathHooks.add(deathHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(DoctorRole.type);
    gameData.dawnHooks.remove(dawnHook);
    gameData.deathHooks.remove(deathHook);
  }

  void dawnHook(GameState gameState, int dayCount) {
    gameState.apply(
      SetDoctorProtectionTargetCommand(
        playerIndex: playerIndex,
        targetPlayerIndex: null,
      ),
    );
  }

  bool deathHook(
    GameState gameState,
    int deadPlayerIndex,
    DeathInformation information,
  ) =>
      gameState.isNight &&
      (gameState.players[playerIndex].role as DoctorRole).protectionTarget ==
          deadPlayerIndex;

  WidgetBuilder nightActionScreen(
    GameState gameState,
    VoidCallback onComplete,
  ) =>
      (BuildContext context) => ActionScreen(
        key: UniqueKey(),
        actionIdentifier: DoctorRole.type,
        appBarTitle: Text(DoctorRole._name(context)),
        selectionCount: 1,
        currentActorIndices: ISet({playerIndex}),
        disabledPlayerIndices:
            (gameState.players[playerIndex].role as DoctorRole)
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
}

@MappableClass(discriminatorValue: 'setDoctorProtectionTarget')
class SetDoctorProtectionTargetCommand
    with SetDoctorProtectionTargetCommandMappable
    implements GameCommand {
  final int playerIndex;
  final int? targetPlayerIndex;

  SetDoctorProtectionTargetCommand({
    required this.playerIndex,
    required this.targetPlayerIndex,
  });

  ({int? previousTarget, List<int> removedPlayersFromCooldown})? _previousData;

  @override
  void apply(GameData gameData) {
    final doctorRole = gameData.players[playerIndex].role as DoctorRole;
    final previousTarget = doctorRole.protectionTarget;

    doctorRole.protectionTarget = targetPlayerIndex;

    final removedPlayersFromCooldown = <int>[];
    if (targetPlayerIndex != null) {
      doctorRole.playersInCooldown.add(targetPlayerIndex!);
      while (doctorRole.playersInCooldown.length >
          doctorRole.protectPlayerCooldown) {
        final removedPlayer = doctorRole.playersInCooldown.removeFirst();
        removedPlayersFromCooldown.add(removedPlayer);
      }
    }

    _previousData = (
      previousTarget: previousTarget,
      removedPlayersFromCooldown: removedPlayersFromCooldown,
    );
  }

  @override
  bool get canBeUndone => _previousData != null;

  @override
  void undo(GameData gameData) {
    final doctorRole = gameData.players[playerIndex].role as DoctorRole;
    final (:previousTarget, :removedPlayersFromCooldown) = _previousData!;
    doctorRole.protectionTarget = previousTarget;
    for (final removedPlayer in removedPlayersFromCooldown.reversed) {
      doctorRole.playersInCooldown.addFirst(removedPlayer);
    }
    _previousData = null;
    doctorRole.playersInCooldown.remove(targetPlayerIndex);
  }
}
