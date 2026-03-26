import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;

@RegisterRole()
class KnightOfTheRustySwordRole extends Role implements DeathReason {
  KnightOfTheRustySwordRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });
  static final RoleType<KnightOfTheRustySwordRole> type =
      RoleType<KnightOfTheRustySwordRole>();
  @override
  RoleType<KnightOfTheRustySwordRole> get objectType => type;

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
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_knightOfTheRustySword_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => ISet({playerIndex});

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
                deathReason: this,
              ),
              UnregisterKnightOfTheRustySwordDawnHookCommand(playerIndex),
            ].lock,
          ),
        );
      }
    }
  }
}

class RegisterKnightOfTheRustySwordDeathHookCommand implements GameCommand {
  const RegisterKnightOfTheRustySwordDeathHookCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    final role =
        gameData.players[playerIndex].role as KnightOfTheRustySwordRole;

    gameData.deathHooks.add(role.deathHook);
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }
}

class RegisterKnightOfTheRustySwordDawnHookCommand implements GameCommand {
  const RegisterKnightOfTheRustySwordDawnHookCommand({
    required this.playerIndex,
    required this.deathDayCounter,
    required this.clockwiseNearestWerewolfIndex,
  });

  final int playerIndex;
  final int deathDayCounter;
  final int clockwiseNearestWerewolfIndex;

  @override
  void apply(GameData gameData) {
    final role =
        gameData.players[playerIndex].role as KnightOfTheRustySwordRole;

    role.killHookData = (
      deathDayCounter: deathDayCounter,
      clockwiseNearestWerewolfIndex: clockwiseNearestWerewolfIndex,
    );

    gameData.dawnHooks.add(role.dawnHook);
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }
}

class UnregisterKnightOfTheRustySwordDawnHookCommand implements GameCommand {
  const UnregisterKnightOfTheRustySwordDawnHookCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    final role =
        gameData.players[playerIndex].role as KnightOfTheRustySwordRole;

    gameData.dawnHooks.remove(role.dawnHook);

    role.killHookData = null;
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }
}
