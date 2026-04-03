import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/doctor.dart'
    show DoctorRole;
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/big_bad_wolf.dart'
    show BigBadWolfRole;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'bodyguard.mapper.dart';

@RegisterRole()
class BodyguardRole extends Role {
  BodyguardRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType type = RoleType.of<BodyguardRole>();
  @override
  RoleType get roleType => type;

  bool hasBeenAttacked = false;
  int? protectionTarget;

  static void registerRole() {
    RoleManager.registerRole<BodyguardRole>(
      type,
      RegisterRoleInformation(
        constructor: BodyguardRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_bodyguard_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_bodyguard_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 5,
        ),
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_bodyguard_name;

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(OnAssignBodyguardCommand(playerIndex));
  }

  bool deathHook(GameState gameState, int deadPlayerIndex, DeathReason reason) {
    if (hasBeenAttacked &&
        deadPlayerIndex != playerIndex &&
        protectionTarget == deadPlayerIndex) {
      gameState.apply(
        MarkDeadCommand.single(player: playerIndex, deathReason: reason),
      );
    }
    if (gameState.isNight &&
        protectionTarget == deadPlayerIndex &&
        gameState.playerAliveUntilDawn(playerIndex)) {
      gameState.apply(MarkBodyguardAttackedCommand(playerIndex));
      return true;
    } else if (deadPlayerIndex == playerIndex) {
      final bool wasProtected = !hasBeenAttacked;
      if (hasBeenAttacked) {
        gameState.apply(RemoveBodyguardDeathHookCommand(playerIndex));
      }
      gameState.apply(
        MarkDeadCommand.single(player: playerIndex, deathReason: reason),
      );
      return wasProtected;
    } else {
      return false;
    }
  }

  void dawnHook(GameState gameState, int dayCount) {
    gameState.apply(
      BodyguardSetProtectionTargetCommand(
        playerIndex: playerIndex,
        targetPlayerIndex: null,
      ),
    );
  }
}

@MappableClass(discriminatorValue: 'onAssignBodyguard')
class OnAssignBodyguardCommand
    with OnAssignBodyguardCommandMappable
    implements GameCommand {
  const OnAssignBodyguardCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;

    gameData.nightActionManager.registerAction(
      BodyguardRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      players: {playerIndex},
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      before: IList([WitchRole.type, BigBadWolfRole.type, WerewolvesTeam.type]),
      after: IList([DoctorRole.type]),
    );

    gameData.dawnHooks.add(bodyguardRole.dawnHook);
    gameData.deathHooks.add(bodyguardRole.deathHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;

    gameData.nightActionManager.unregisterAction(BodyguardRole.type);

    gameData.dawnHooks.remove(bodyguardRole.dawnHook);
    gameData.deathHooks.remove(bodyguardRole.deathHook);
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      // TODO: show when the bodyguard has already been attacked
      (BuildContext context) => ActionScreen(
        key: UniqueKey(),
        actionIdentifier: BodyguardRole.type,
        appBarTitle: Text(BodyguardRole._name(context)),
        selectionCount: 1,
        currentActorIndices: ISet({playerIndex}),
        instruction: Text(
          AppLocalizations.of(context).role_bodyguard_nightAction_instruction,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        onConfirm: (playerIds, gameState) {
          gameState.apply(
            BodyguardSetProtectionTargetCommand(
              playerIndex: playerIndex,
              targetPlayerIndex: playerIds.singleOrNull,
            ),
          );
          onComplete();
        },
      );
}

@MappableClass(discriminatorValue: 'removeBodyguardDeathHook')
class RemoveBodyguardDeathHookCommand
    with RemoveBodyguardDeathHookCommandMappable
    implements GameCommand {
  const RemoveBodyguardDeathHookCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;
    gameData.deathHooks.remove(bodyguardRole.deathHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;
    gameData.deathHooks.add(bodyguardRole.deathHook);
  }
}

@MappableClass(discriminatorValue: 'bodyguardSetProtectionTarget')
class BodyguardSetProtectionTargetCommand
    with BodyguardSetProtectionTargetCommandMappable
    implements GameCommand {
  final int playerIndex;
  final int? targetPlayerIndex;

  BodyguardSetProtectionTargetCommand({
    required this.playerIndex,
    required this.targetPlayerIndex,
  });

  int? _previousProtectionTarget;

  @override
  void apply(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;
    _previousProtectionTarget = bodyguardRole.protectionTarget;
    bodyguardRole.protectionTarget = targetPlayerIndex;
  }

  @override
  bool get canBeUndone => _previousProtectionTarget != null;

  @override
  void undo(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;
    bodyguardRole.protectionTarget = _previousProtectionTarget;
    _previousProtectionTarget = null;
  }
}

@MappableClass(discriminatorValue: 'markBodyguardAttacked')
class MarkBodyguardAttackedCommand
    with MarkBodyguardAttackedCommandMappable
    implements GameCommand {
  final int playerIndex;

  MarkBodyguardAttackedCommand(this.playerIndex);

  bool? _previousHasBeenAttacked;

  @override
  void apply(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;
    _previousHasBeenAttacked = bodyguardRole.hasBeenAttacked;
    bodyguardRole.hasBeenAttacked = true;
  }

  @override
  bool get canBeUndone => _previousHasBeenAttacked != null;

  @override
  void undo(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;
    bodyguardRole.hasBeenAttacked = _previousHasBeenAttacked!;
    _previousHasBeenAttacked = null;
  }
}
