import 'package:dart_mappable/dart_mappable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/commands/composite.dart';
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason, DeathReasonMapper;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;

part 'knight_of_the_rusty_sword.mapper.dart';

@RegisterRole()
class KnightOfTheRustySwordRole extends Role {
  KnightOfTheRustySwordRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType type = RoleType.of<KnightOfTheRustySwordRole>();
  @override
  RoleType get roleType => type;

  ({int deathDayCounter, int clockwiseNearestWerewolfIndex})? killHookData;

  static void registerRole() {
    RoleManager.registerRole<KnightOfTheRustySwordRole>(
      type,
      RegisterRoleInformation(
        constructor: KnightOfTheRustySwordRole._,
        name: (context) =>
            AppLocalizations.of(context).role_knightOfTheRustySword_name,
        description: (context) =>
            AppLocalizations.of(context).role_knightOfTheRustySword_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_knightOfTheRustySword_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 25,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterKnightOfTheRustySwordDeathHookCommand(playerIndex));
  }

  bool deathHook(
    GameState deathGameState,
    int deathPlayerIndex,
    DeathReason reason,
  ) {
    if (playerIndex == deathPlayerIndex && reason is WerewolvesDeathReason) {
      final int playerCount = deathGameState.players.length;

      final int? clockwiseNearestWerewolfIndex =
          List.generate(
                deathGameState.players.length - 1,
                (i) => (playerIndex + i + 1) % playerCount,
              )
              .where(
                (i) =>
                    deathGameState.players[i].role?.team(deathGameState) ==
                        WerewolvesTeam.type &&
                    deathGameState.playerAliveUntilDawn(i),
              )
              .firstOrNull;
      if (clockwiseNearestWerewolfIndex != null) {
        final deathDayCounter = deathGameState.dayCounter;
        deathGameState.apply(
          RegisterKnightOfTheRustySwordDawnHookCommand(
            playerIndex: playerIndex,
            deathDayCounter: deathDayCounter,
            clockwiseNearestWerewolfIndex: clockwiseNearestWerewolfIndex,
          ),
        );
      }
    }

    return false;
  }

  void dawnHook(GameState dawnGameState, int dayCount) {
    if (killHookData != null) {
      final (:deathDayCounter, :clockwiseNearestWerewolfIndex) = killHookData!;

      if (deathDayCounter + 2 == dayCount) {
        dawnGameState.apply(
          CompositeGameCommand(
            <GameCommand>[
              MarkDeadCommand.single(
                player: clockwiseNearestWerewolfIndex,
                deathReason: KnightOfTheRustySwordRoleDeathReason(playerIndex),
              ),
              UnregisterKnightOfTheRustySwordDawnHookCommand(playerIndex),
            ].lock,
          ),
        );
      }
    }
  }
}

@MappableClass(discriminatorValue: 'knightOfTheRustySword')
class KnightOfTheRustySwordRoleDeathReason
    with KnightOfTheRustySwordRoleDeathReasonMappable
    implements DeathReason {
  const KnightOfTheRustySwordRoleDeathReason(this.playerIndex);

  final int playerIndex;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_knightOfTheRustySword_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => ISet({playerIndex});
}

@MappableClass(discriminatorValue: 'registerKnightOfTheRustySwordDeathHook')
class RegisterKnightOfTheRustySwordDeathHookCommand
    with RegisterKnightOfTheRustySwordDeathHookCommandMappable
    implements GameCommand {
  const RegisterKnightOfTheRustySwordDeathHookCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    final role =
        gameData.players[playerIndex].role as KnightOfTheRustySwordRole;

    gameData.deathHooks.add(role.deathHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    final role =
        gameData.players[playerIndex].role as KnightOfTheRustySwordRole;

    gameData.deathHooks.remove(role.deathHook);
  }
}

@MappableClass(discriminatorValue: 'registerKnightOfTheRustySwordDawnHook')
class RegisterKnightOfTheRustySwordDawnHookCommand
    with RegisterKnightOfTheRustySwordDawnHookCommandMappable
    implements GameCommand {
  final int playerIndex;
  final int deathDayCounter;
  final int clockwiseNearestWerewolfIndex;

  RegisterKnightOfTheRustySwordDawnHookCommand({
    required this.playerIndex,
    required this.deathDayCounter,
    required this.clockwiseNearestWerewolfIndex,
  });

  Option<({int clockwiseNearestWerewolfIndex, int deathDayCounter})?>
  _previousKillHookData = Option.none();

  @override
  void apply(GameData gameData) {
    final role =
        gameData.players[playerIndex].role as KnightOfTheRustySwordRole;

    _previousKillHookData = Option.of(role.killHookData);
    role.killHookData = (
      deathDayCounter: deathDayCounter,
      clockwiseNearestWerewolfIndex: clockwiseNearestWerewolfIndex,
    );

    gameData.dawnHooks.add(role.dawnHook);
  }

  @override
  bool get canBeUndone => _previousKillHookData.isSome();

  @override
  void undo(GameData gameData) {
    final role =
        gameData.players[playerIndex].role as KnightOfTheRustySwordRole;

    gameData.dawnHooks.remove(role.dawnHook);

    role.killHookData = _previousKillHookData.getOrElse(() => null);
  }
}

@MappableClass(discriminatorValue: 'unregisterKnightOfTheRustySwordDawnHook')
class UnregisterKnightOfTheRustySwordDawnHookCommand
    with UnregisterKnightOfTheRustySwordDawnHookCommandMappable
    implements GameCommand {
  final int playerIndex;

  UnregisterKnightOfTheRustySwordDawnHookCommand(this.playerIndex);

  Option<({int clockwiseNearestWerewolfIndex, int deathDayCounter})?>
  _previousKillHookData = Option.none();

  @override
  void apply(GameData gameData) {
    final role =
        gameData.players[playerIndex].role as KnightOfTheRustySwordRole;

    gameData.dawnHooks.remove(role.dawnHook);

    _previousKillHookData = Option.of(role.killHookData);
    role.killHookData = null;
  }

  @override
  bool get canBeUndone => _previousKillHookData.isSome();

  @override
  void undo(GameData gameData) {
    final role =
        gameData.players[playerIndex].role as KnightOfTheRustySwordRole;

    role.killHookData = _previousKillHookData.getOrElse(() => null);

    gameData.dawnHooks.add(role.dawnHook);
  }
}
