import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;

class KnightOfTheRustySwordRole extends Role implements DeathReason {
  KnightOfTheRustySwordRole._();
  static final RoleType type = RoleType<KnightOfTheRustySwordRole>();
  @override
  RoleType get objectType => type;

  static final Role instance = KnightOfTheRustySwordRole._();

  static void registerRole() {
    RoleManager.registerRole<KnightOfTheRustySwordRole>(
      RegisterRoleInformation(KnightOfTheRustySwordRole._, instance),
    );
  }

  @override
  Iterable<int> get validRoleCounts => const [1];
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context).role_knightOfTheRustySword_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context).role_knightOfTheRustySword_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    return AppLocalizations.of(
      context,
    ).role_knightOfTheRustySword_checkInstruction(count: count);
  }

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_knightOfTheRustySword_deathReason;

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.deathHooks.add((deathGameState, deathPlayerIndex, reason) {
      if (playerIndex == deathPlayerIndex && reason is WerewolvesTeam) {
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
