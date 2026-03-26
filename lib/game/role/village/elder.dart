import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;

@RegisterRole()
class ElderRole extends Role {
  ElderRole._({required RoleConfiguration config, required super.playerIndex});
  static final RoleType<ElderRole> type = RoleType<ElderRole>();
  @override
  RoleType<ElderRole> get objectType => type;

  bool hasBeenAttackedByWerewolves = false;

  static void registerRole() {
    RoleManager.registerRole<ElderRole>(
      type,
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
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(OnAssignElderCommand(playerIndex));
  }
}

class OnAssignElderCommand implements GameCommand {
  const OnAssignElderCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.deathHooks.add(deathHook);
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }

  bool deathHook(
    GameState deathGameState,
    int deathPlayerIndex,
    DeathReason reason,
  ) {
    final elderRole = deathGameState.players[playerIndex].role as ElderRole;

    if (playerIndex == deathPlayerIndex) {
      if (reason is WerewolvesDeathReason) {
        if (!elderRole.hasBeenAttackedByWerewolves) {
          deathGameState.apply(MarkElderAsAttackedCommand(playerIndex));
          // TODO: still allow witch to heal the elder if attacked by werewolves for the first time
          return true;
        }
      } else {
        final responsibleDeathPlayers = reason.responsiblePlayerIndices;
        deathGameState.apply(
          ElderDeathPreventAbilitiesCommand(
            playerIndex: playerIndex,
            responsibleDeathPlayers: responsibleDeathPlayers,
          ),
        );
      }
    }

    return false;
  }
}

class MarkElderAsAttackedCommand implements GameCommand {
  MarkElderAsAttackedCommand(this.playerIndex);

  final int playerIndex;

  bool? previousHasBeenAttacked;

  @override
  void apply(GameData gameData) {
    final elderRole = gameData.players[playerIndex].role as ElderRole;
    previousHasBeenAttacked = elderRole.hasBeenAttackedByWerewolves;
    elderRole.hasBeenAttackedByWerewolves = true;
  }

  @override
  bool get canBeUndone => previousHasBeenAttacked != null;

  @override
  void undo(GameData gameData) {
    final elderRole = gameData.players[playerIndex].role as ElderRole;
    elderRole.hasBeenAttackedByWerewolves = previousHasBeenAttacked!;
    previousHasBeenAttacked = null;
  }
}

class ElderDeathPreventAbilitiesCommand implements GameCommand {
  const ElderDeathPreventAbilitiesCommand({
    required this.playerIndex,
    required this.responsibleDeathPlayers,
  });

  final int playerIndex;
  final ISet<int> responsibleDeathPlayers;

  @override
  void apply(GameData gameData) {
    gameData.nightActionHooks.add(nightActionHook);
    gameData.dayActionHooks.add(dayActionHook);
    gameData.deathActionHooks.add(deathActionHook);
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }

  bool nightActionHook(
    GameState nightActionGameState,
    Object? phaseIdentifier,
    ISet<int> phasePlayers,
  ) =>
      responsibleDeathPlayers.containsAll(phasePlayers) &&
      phasePlayers.isNotEmpty &&
      phasePlayers.every(
        (playerIndex) =>
            !nightActionGameState.playerAliveUntilDawn(playerIndex) ||
            nightActionGameState.players[playerIndex].role?.team(
                  nightActionGameState,
                ) ==
                VillageTeam.type,
      );

  bool dayActionHook(
    GameState dayActionGameState,
    Object? phaseIdentifier,
    ISet<int> phasePlayers,
  ) =>
      responsibleDeathPlayers.containsAll(phasePlayers) &&
      phasePlayers.isNotEmpty &&
      phasePlayers.every(
        (playerIndex) =>
            !dayActionGameState.playerAliveUntilDawn(playerIndex) ||
            dayActionGameState.players[playerIndex].role?.team(
                  dayActionGameState,
                ) ==
                VillageTeam.type,
      );

  bool deathActionHook(
    GameState deathActionGameState,
    Object? phaseIdentifier,
    ISet<int> phasePlayers,
  ) =>
      responsibleDeathPlayers.containsAll(phasePlayers) &&
      phasePlayers.isNotEmpty &&
      phasePlayers.every(
        (playerIndex) =>
            deathActionGameState.players[playerIndex].role?.team(
              deathActionGameState,
            ) ==
            VillageTeam.type,
      );
}
