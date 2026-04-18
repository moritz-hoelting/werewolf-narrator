import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show FpdartOnOption, Option;
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathInformation, DeathReason, DeathReasonMapper;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/doctor.dart'
    show DoctorRole;
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/big_bad_wolf.dart'
    show BigBadWolfRole;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/game/util/hooks.dart';
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

  bool deathHook(
    GameState gameState,
    int deadPlayerIndex,
    DeathInformation information,
  ) {
    if (hasBeenAttacked &&
        deadPlayerIndex != playerIndex &&
        protectionTarget == deadPlayerIndex) {
      gameState.apply(
        MarkDeadCommand.single(
          player: playerIndex,
          deathReason: BodyguardProtectionDeathReason(
            responsiblePlayers: ISet({protectionTarget!}),
          ),
        ),
      );
    }
    if (gameState.isNight &&
        protectionTarget == deadPlayerIndex &&
        gameState.players[playerIndex].isAlive) {
      gameState.apply(MarkBodyguardAttackedCommand(playerIndex));
      return true;
    } else if (deadPlayerIndex == playerIndex) {
      final bool wasProtected = !hasBeenAttacked;
      gameState.apply(MarkBodyguardAttackedCommand(playerIndex));
      if (hasBeenAttacked) {
        gameState.apply(RemoveBodyguardDeathHookCommand(playerIndex));
      }
      gameState.apply(
        MarkDeadCommand.single(
          player: playerIndex,
          deathReason: BodyguardProtectionDeathReason(
            responsiblePlayers: ISet({protectionTarget!}),
          ),
        ),
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

@MappableClass(discriminatorValue: 'bodyguardProtection')
class BodyguardProtectionDeathReason
    with BodyguardProtectionDeathReasonMappable
    implements DeathReason {
  const BodyguardProtectionDeathReason({required this.responsiblePlayers});

  final ISet<int> responsiblePlayers;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_bodyguard_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => responsiblePlayers;
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
      (gameState, onComplete) => nightActionScreen(onComplete),
      players: {playerIndex},
      conditioned: (gameState) => gameState.players[playerIndex].isAlive,
      before: ISet({WitchRole.type, BigBadWolfRole.type, WerewolvesTeam.type}),
      after: ISet({DoctorRole.type}),
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

  WidgetBuilder nightActionScreen(VoidCallback onComplete) =>
      (BuildContext context) {
        final gameState = Provider.of<GameState>(context, listen: false);
        final bodyguardRole =
            gameState.players[playerIndex].role as BodyguardRole;
        final hasBeenAttacked = bodyguardRole.hasBeenAttacked;

        return ActionScreen(
          key: UniqueKey(),
          actionIdentifier: BodyguardRole.type,
          appBarTitle: Text(BodyguardRole._name(context)),
          selectionCount: 1,
          currentActorIndices: ISet({playerIndex}),
          disabledPlayerIndices: ISet({playerIndex}),
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
          playerSpecificDisplayData: hasBeenAttacked
              ? IMap({
                  playerIndex: PlayerDisplayData(
                    trailing: (context) => const Icon(Icons.gpp_maybe),
                  ),
                })
              : const IMap<int, PlayerDisplayData>.empty(),
        );
      };
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

  Option<int?> _previousProtectionTarget = const Option.none();

  @override
  void apply(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;
    _previousProtectionTarget = Option.of(bodyguardRole.protectionTarget);
    bodyguardRole.protectionTarget = targetPlayerIndex;
  }

  @override
  bool get canBeUndone => _previousProtectionTarget.isSome();

  @override
  void undo(GameData gameData) {
    final bodyguardRole = gameData.players[playerIndex].role as BodyguardRole;
    bodyguardRole.protectionTarget = _previousProtectionTarget.getOrElse(
      () => null,
    );
    _previousProtectionTarget = const Option.none();
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
