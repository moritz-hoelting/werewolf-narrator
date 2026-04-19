import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathInformation;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

part 'elder.mapper.dart';

@RegisterRole()
class ElderRole extends Role {
  ElderRole._({required RoleConfiguration config, required super.playerIndex});
  static final RoleType type = RoleType.of<ElderRole>();
  @override
  RoleType get roleType => type;

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
        chooseRolesInformation: const ChooseRolesInformation(
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

@MappableClass(discriminatorValue: 'onAssignElder')
class OnAssignElderCommand
    with OnAssignElderCommandMappable
    implements GameCommand {
  const OnAssignElderCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.deathHooks.add(deathHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.deathHooks.remove(deathHook);
  }

  bool deathHook(
    GameState deathGameState,
    int deathPlayerIndex,
    DeathInformation information,
  ) {
    final elderRole = deathGameState.players[playerIndex].role as ElderRole;

    if (playerIndex == deathPlayerIndex) {
      if (information.reason is WerewolvesDeathReason) {
        if (!elderRole.hasBeenAttackedByWerewolves) {
          deathGameState.apply(MarkElderAsAttackedCommand(playerIndex));
          return true;
        }
      } else {
        final responsibleDeathPlayers =
            information.reason.responsiblePlayerIndices;
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

@MappableClass(discriminatorValue: 'markElderAsAttacked')
class MarkElderAsAttackedCommand
    with MarkElderAsAttackedCommandMappable
    implements GameCommand {
  final int playerIndex;

  MarkElderAsAttackedCommand(this.playerIndex);

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

@MappableClass(discriminatorValue: 'elderDeathPreventAbilities')
class ElderDeathPreventAbilitiesCommand
    with ElderDeathPreventAbilitiesCommandMappable
    implements GameCommand {
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
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionHooks.remove(nightActionHook);
    gameData.dayActionHooks.remove(dayActionHook);
    gameData.deathActionHooks.remove(deathActionHook);
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
            !nightActionGameState.players[playerIndex].isAlive ||
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
            !dayActionGameState.players[playerIndex].isAlive ||
            dayActionGameState.players[playerIndex].role?.team(
                  dayActionGameState,
                ) ==
                VillageTeam.type,
      );

  bool deathActionHook(
    GameState deathActionGameState,
    Object? phaseIdentifier,
    int phasePlayer,
  ) =>
      responsibleDeathPlayers.contains(phasePlayer) &&
      deathActionGameState.players[phasePlayer].role?.team(
            deathActionGameState,
          ) ==
          VillageTeam.type;
}
