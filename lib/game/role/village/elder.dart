import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;

class ElderRole extends Role {
  ElderRole._();
  static final RoleType type = RoleType<ElderRole>();
  @override
  RoleType get objectType => type;

  bool hasBeenAttackedByWerewolves = false;

  static void registerRole() {
    RoleManager.registerRole<ElderRole>(
      RegisterRoleInformation(
        constructor: ElderRole._,
        name: (context) => AppLocalizations.of(context).role_elder_name,
        description: (context) =>
            AppLocalizations.of(context).role_elder_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_elder_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 20,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.deathHooks.add((deathGameState, deathPlayerIndex, reason) {
      if (playerIndex == deathPlayerIndex) {
        if (reason is WerewolvesDeathReason && !hasBeenAttackedByWerewolves) {
          hasBeenAttackedByWerewolves = true;
          // TODO: still allow witch to heal the elder if attacked by werewolves for the first time
          return true;
        }
        final responsibleDeathPlayers = reason.responsiblePlayerIndices;
        deathGameState.nightActionHooks.add((
          nightActionGameState,
          phaseIdentifier,
          phasePlayers,
        ) {
          return responsibleDeathPlayers.containsAll(phasePlayers) &&
              phasePlayers.isNotEmpty &&
              phasePlayers.every(
                (playerIndex) =>
                    !nightActionGameState.playerAliveUntilDawn(playerIndex) ||
                    nightActionGameState.players[playerIndex].role?.team(
                          nightActionGameState,
                        ) ==
                        VillageTeam.type,
              );
        });
        deathGameState.dayActionHooks.add((
          dayActionGameState,
          phaseIdentifier,
          phasePlayers,
        ) {
          return responsibleDeathPlayers.containsAll(phasePlayers) &&
              phasePlayers.isNotEmpty &&
              phasePlayers.every(
                (playerIndex) =>
                    !dayActionGameState.playerAliveUntilDawn(playerIndex) ||
                    dayActionGameState.players[playerIndex].role?.team(
                          dayActionGameState,
                        ) ==
                        VillageTeam.type,
              );
        });
        deathGameState.deathActionHooks.add((
          deathActionGameState,
          phaseIdentifier,
          phasePlayers,
        ) {
          return responsibleDeathPlayers.containsAll(phasePlayers) &&
              phasePlayers.isNotEmpty &&
              phasePlayers.every(
                (playerIndex) =>
                    deathActionGameState.players[playerIndex].role?.team(
                      deathActionGameState,
                    ) ==
                    VillageTeam.type,
              );
        });
      }

      return false;
    });
  }
}
