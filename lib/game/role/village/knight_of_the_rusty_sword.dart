import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;

class KnightOfTheRustySwordRole extends Role implements DeathReason {
  KnightOfTheRustySwordRole._();
  static final RoleType type = RoleType<KnightOfTheRustySwordRole>();
  @override
  RoleType get objectType => type;

  int? playerIndex;

  static void registerRole() {
    RoleManager.registerRole<KnightOfTheRustySwordRole>(
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
      ),
    );
  }

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_knightOfTheRustySword_deathReason;

  @override
  Set<int> get responsiblePlayerIndices => {playerIndex!};

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    this.playerIndex = playerIndex;

    gameState.deathHooks.add((deathGameState, deathPlayerIndex, reason) {
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
          void dawnHook(dawnGameState, dayCount) {
            if (deathDayCounter + 2 == dayCount) {
              dawnGameState.markPlayerDead(clockwiseNearestWerewolfIndex, this);
              dawnGameState.dawnHooks.remove(dawnHook);
            }
          }

          deathGameState.dawnHooks.add(dawnHook);
        }
      }

      return false;
    });
  }
}
