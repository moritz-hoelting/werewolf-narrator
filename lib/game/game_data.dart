import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/game/commands/fill_villager_roles.dart'
    show FillVillagerRolesCommand;
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart'
    show GameConfiguration, RoleConfiguration;
import 'package:werewolf_narrator/game/model/death_information.dart';
import 'package:werewolf_narrator/game/model/player.dart';
import 'package:werewolf_narrator/game/model/role.dart' show RoleType;
import 'package:werewolf_narrator/game/model/team.dart'
    show TeamManager, TeamType;
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition;
import 'package:werewolf_narrator/game/role/role.dart' show Role;
import 'package:werewolf_narrator/game/team/team.dart' show Team;
import 'package:werewolf_narrator/game/util/dynamic_actions.dart'
    show DynamicActionManager;
import 'package:werewolf_narrator/game/util/hooks.dart';
import 'package:werewolf_narrator/views/game/check_roles_screen.dart'
    show CheckRolesData;
import 'package:werewolf_narrator/views/game/dynamic_actions_screen.dart'
    show DetermineFirstDynamicActionIndexCommand;

part 'game_data.mapper.dart';

class GameData {
  GameData({
    required this.state,
    required Iterable<String> playerNames,
    required this.gameConfiguration,
    required this.roleConfigurations,
  }) : players = playerNames.map((name) => Player(name)).toList(),
       teams = Map.fromEntries(
         roleConfigurations.entries
             .where((entry) => entry.value.count > 0)
             .map((entry) => entry.key.information.initialTeam)
             .nonNulls
             .toSet()
             .map(
               (teamType) =>
                   MapEntry(teamType, TeamManager.instantiateTeam(teamType)),
             ),
       ),
       startGameWithDay = roleConfigurations.entries.any(
         (entry) =>
             entry.value.count > 0 &&
             entry.key.information.requireStartGameWithDay,
       ),
       checkRolesData = CheckRolesData(roleConfigurations) {
    assert(
      players.length ==
          roleConfigurations.entries.fold(
            0,
            (sum, entry) =>
                sum +
                entry.value.count +
                (entry.value.count *
                    (1 - entry.key.information.addedRoleCardAmount)),
          ),
      'Number of players must match total number of roles assigned (correctly accounting for Thief roles)',
    );
  }

  /// Game state wrapper object
  final GameState state;

  /// Handles night actions for this game state.
  final DynamicActionManager nightActionManager = DynamicActionManager();

  /// Handles day actions for this game state.
  final DynamicActionManager dayActionManager = DynamicActionManager();

  /// The list of players in this game.
  final List<Player> players;

  /// The teams present in this game.
  final Map<TeamType, Team> teams;

  /// The counts of roles present in this game (initialized during setup).
  final Map<RoleType, ({int count, RoleConfiguration config})>
  roleConfigurations;

  /// The game configuration, storing arbitrary configuration options.
  final GameConfiguration gameConfiguration;

  /// Whether the game starts with a day phase (instead of night).
  final bool startGameWithDay;

  /// Conditions under which the game is considered to be won.
  final List<WinCondition> winConditions = [];

  /// Hooks run at dawn.
  final List<DawnHook> dawnHooks = [];

  /// Hooks when a player is marked dead.
  ///
  /// Can prevent death by returning true.
  final List<DeathHook> deathHooks = [];

  /// Hooks when a player is displayed.
  final List<PlayerDisplayHook> playerDisplayHooks = [];

  /// Hooks when a night action is displayed.
  ///
  /// Can prevent the action from being displayed for the given players by returning true.
  final List<ActionHook> nightActionHooks = [];

  /// Hooks when a day action is displayed.
  ///
  /// Can prevent the action from being displayed for the given players by returning true.
  final List<ActionHook> dayActionHooks = [];

  /// Hooks when a death action is displayed.
  ///
  /// Can prevent the action from being displayed for the given players by returning true.
  /// Will be called multiple times per death for determining whether to show the action. The answer must be consistent.
  final List<DeathActionHook> deathActionHooks = [];

  /// Hooks for remaining roles at the end of role assignment.
  ///
  /// Called with the count of remaining roles for each role type.
  final Map<RoleType, List<RemainingRoleHook>> remainingRoleHooks = {};

  /// Hooks to determine if a player has won alongside the winning team.
  ///
  /// Returning true adds the player as a winner, false excludes them,
  /// and null has no effect.
  final List<PlayerWinHook> playerWinHooks = [];

  int? dynamicActionIndex;

  CheckRolesData checkRolesData;

  int _dayCounter = 0;
  GamePhase _phase = GamePhase.dusk;

  // Guard against recursive calls in markPlayerDead.
  final List<int> _markDeadRecursionGuard = [];

  final Map<int, List<DeathInformation>> _pendingDeaths = {};
  final Set<int> _unannouncedDeaths = {};

  final Map<dynamic, dynamic> customData = {};

  /// The current day counter.
  int get dayCounter => _dayCounter;

  /// The current phase of the game.
  GamePhase get phase => _phase;

  /// Whether the game is currently in a night phase.
  bool get isNight => phase.isNight;

  /// The total number of players in the game.
  int get playerCount => players.length;

  /// The number of alive players in the game.
  int get alivePlayerCount => players.where((player) => player.isAlive).length;

  /// Returns a map of player indices to their death reasons for the given cycle.
  IMap<int, IList<DeathReason>> deathsInCycle(int dayCounter, bool atNight) =>
      players
          .asMap()
          .entries
          .map((entry) => MapEntry(entry.key, entry.value.deathInformation))
          .followedBy(_pendingDeaths.entries)
          .fold(<int, List<DeathReason>>{}, (acc, entry) {
            final playerIndex = entry.key;
            final deathInfos = entry.value;
            if (deathInfos.isNotEmpty) {
              acc[playerIndex] ??= [];
              acc[playerIndex]!.addAll(
                deathInfos
                    .where(
                      (deathInfo) =>
                          deathInfo.atNight == atNight &&
                          deathInfo.day == dayCounter,
                    )
                    .map((deathInfo) => deathInfo.reason),
              );
            }
            return acc;
          })
          .map((key, value) => MapEntry(key, value.lock))
          .lock;

  /// Returns a map of player indices to their death reasons for the current cycle (day/night).
  IMap<int, IList<DeathReason>> get currentCycleDeaths =>
      deathsInCycle(dayCounter, isNight);

  /// Returns a map of player indices to their death reasons for the previous cycle (day/night).
  IMap<int, IList<DeathReason>> get previousCycleDeaths =>
      deathsInCycle(isNight ? dayCounter : dayCounter - 1, !isNight);

  /// Checks if the game has a specific role.
  bool hasRole(RoleType role) =>
      roleConfigurations.containsKey(role) &&
      roleConfigurations[role]!.count > 0;

  /// Checks if the game has a specific role.
  bool hasRoleType<T extends Role>() => hasRole(RoleType.of<T>());

  /// Checks if the game has a specific role with at least one alive player.
  bool hasAliveRole(RoleType role) =>
      hasRole(role) &&
      players.indexed.any(
        (p) => p.$2.role != null && p.$2.role!.roleType == role && p.$2.isAlive,
      );

  /// Checks if the game has a specific role with at least one alive player.
  bool hasAliveRoleType<T extends Role>() => hasAliveRole(RoleType.of<T>());

  /// Returns index and the player with a specific role, if any.
  ({int index, Player player})? getPlayerOfRole(RoleType role) => players
      .mapIndexed((index, player) => (index: index, player: player))
      .singleWhereOrNull(
        (player) =>
            player.player.role != null && player.player.role!.roleType == role,
      );

  /// Returns index and the player with a specific role, if any.
  ({int index, Player player})? getPlayerOfRoleType<T extends Role>() =>
      getPlayerOfRole(RoleType.of<T>());

  /// Returns index and the alive player with a specific role, if any.
  ({int index, Player player})? getAlivePlayerOfRole(RoleType role) => players
      .mapIndexed((index, player) => (index: index, player: player))
      .singleWhereOrNull(
        (entry) =>
            entry.player.role != null &&
            entry.player.role!.roleType == role &&
            entry.player.isAlive,
      );

  /// Returns index and the alive player with a specific role, if any.
  ({int index, Player player})? getAlivePlayerOfRoleType<T extends Role>() =>
      getAlivePlayerOfRole(RoleType.of<T>());

  /// Returns a list of indices and players with a specific role.
  IList<({int index, Player player})> getPlayersOfRole(RoleType role) => players
      .mapIndexed((index, player) => (index: index, player: player))
      .where(
        (entry) =>
            entry.player.role != null && entry.player.role!.roleType == role,
      )
      .toIList();

  /// Returns a list of indices and players with a specific role.
  IList<({int index, Player player})> getPlayersOfRoleType<T extends Role>() =>
      getPlayersOfRole(RoleType.of<T>());

  /// Returns a list of indices and alive players with a specific role.
  IList<({int index, Player player})> getAlivePlayersOfRole(RoleType role) =>
      players
          .mapIndexed((index, player) => (index: index, player: player))
          .where(
            (entry) =>
                entry.player.role != null &&
                entry.player.role!.roleType == role &&
                entry.player.isAlive,
          )
          .toIList();

  /// Returns a list of indices and alive players with a specific role.
  IList<({int index, Player player})>
  getAlivePlayersOfRoleType<T extends Role>() =>
      getAlivePlayersOfRole(RoleType.of<T>());

  /// Checks if the game has a specific team.
  bool hasPlayerOfTeam(TeamType team) => players.any(
    (player) => player.role != null && player.role!.team(state) == team,
  );

  /// Checks if the game has a specific team.
  bool hasPlayerOfTeamType<T extends Team>() =>
      hasPlayerOfTeam(TeamType.of<T>());

  /// Checks if the game has an alive player of the specific team.
  bool hasAlivePlayerOfTeam(TeamType team) => players.indexed.any(
    (player) =>
        player.$2.isAlive &&
        player.$2.role != null &&
        player.$2.role!.team(state) == team,
  );

  /// Checks if the game has an alive player of the specific team.
  bool hasAlivePlayerOfTeamType<T extends Team>() =>
      hasAlivePlayerOfTeam(TeamType.of<T>());

  /// Returns a list of indices and players belonging to a specific team.
  IList<({int index, Player player})> getPlayersOfTeam(TeamType team) => players
      .mapIndexed((index, player) => (index: index, player: player))
      .where(
        (entry) =>
            entry.player.role != null && entry.player.role!.team(state) == team,
      )
      .toIList();

  /// Returns a list of indices and players belonging to a specific team.
  IList<({int index, Player player})> getPlayersOfTeamType<T extends Team>() =>
      getPlayersOfTeam(TeamType.of<T>());

  /// Returns a list of indices and alive players belonging to a specific team.
  IList<({int index, Player player})> getAlivePlayersOfTeam(TeamType team) =>
      players
          .mapIndexed((index, player) => (index: index, player: player))
          .where(
            (entry) =>
                entry.player.role != null &&
                entry.player.role!.team(state) == team &&
                entry.player.isAlive,
          )
          .toIList();

  /// Returns a list of indices and alive players belonging to a specific team.
  IList<({int index, Player player})>
  getAlivePlayersOfTeamType<T extends Team>() =>
      getAlivePlayersOfTeam(TeamType.of<T>());

  /// Returns a list of unassigned roles in the game.
  IList<RoleType> get unassignedRoles {
    final assignedRoles = players.map((player) => player.role).fold(
      <RoleType, int>{},
      (acc, element) {
        if (element != null) {
          acc[element.roleType] = (acc[element.roleType] ?? 0) + 1;
        }
        return acc;
      },
    );

    return roleConfigurations.entries
        .map((entry) {
          final assignedCount = assignedRoles[entry.key] ?? 0;
          return (entry.key, entry.value.count - assignedCount);
        })
        .fold(<RoleType>[], (acc, element) {
          for (var i = 0; i < element.$2; i++) {
            acc.add(element.$1);
          }
          return acc;
        })
        .lock;
  }

  void _markPlayerActuallyDead(
    int playerIndex,
    DeathInformation deathInformation,
  ) {
    if (_markDeadRecursionGuard.contains(playerIndex)) {
      return;
    }
    _markDeadRecursionGuard.add(playerIndex);
    var shouldDie = true;
    for (final hook in deathHooks) {
      if (hook(state, playerIndex, deathInformation)) {
        shouldDie = false;
      }
    }
    if (shouldDie) {
      players[playerIndex].markDead(deathInformation);
    }
    _markDeadRecursionGuard.remove(playerIndex);
  }

  /// Marks a player as dead with the given death reason.
  void markPlayerDead(int playerIndex, DeathReason deathReason) {
    final deathInformation = DeathInformation(
      reason: deathReason,
      day: dayCounter,
      atNight: isNight,
    );
    _pendingDeaths[playerIndex] ??= [];
    _pendingDeaths[playerIndex]!.add(deathInformation);
  }

  /// Removes a pending death for a player with the given reason.
  void removeFromPendingDeaths(int playerIndex, DeathReason reason) {
    _pendingDeaths[playerIndex]?.removeWhere(
      (deathInfo) => deathInfo.reason == reason,
    );
    if (_pendingDeaths[playerIndex]?.isEmpty == true) {
      _pendingDeaths.remove(playerIndex);
    }
  }

  /// Player indices that are alive.
  ISet<int> get alivePlayerIndices => players.indexed
      .where((player) => player.$2.isAlive)
      .map((player) => player.$1)
      .toISet();

  /// Player indices that are dead.
  ISet<int> get deadPlayerIndices => players.indexed
      .where((player) => !player.$2.isAlive)
      .map((player) => player.$1)
      .toISet();

  /// The index of the first player with pending death actions, or null if there are none.
  int? get firstPlayerWithPendingDeathAction =>
      Iterable.generate(playerCount, (i) => i).firstWhereOrNull((index) {
        final player = players[index];
        return player.role != null &&
            player.role!.hasDeathScreen(state) &&
            player.waitForDeathAction(state);
      });

  IMap<int, IList<DeathInformation>> get pendingDeaths =>
      _pendingDeaths.lock.map((key, value) => MapEntry(key, value.lock));

  /// Deaths that have occurred but have not yet been announced to the players, mapped by player index.
  ISet<int> get unannouncedDeaths => _unannouncedDeaths.lock;

  /// Whether there are pending death announcements to be made.
  bool get hasPendingDeathAnnouncements => _unannouncedDeaths.isNotEmpty;

  /// Whether there are pending death announcements to be made for deaths that occurred during the night.
  bool get hasPendingDeathAnnouncementsFromNight => _unannouncedDeaths.any(
    (playerIndex) => players[playerIndex].deathInformation.any(
      (info) => info.atNight == true,
    ),
  );

  (int, int) getAliveNeighbors(int playerIndex) {
    final livingIndices = List.generate(
      players.length,
      (i) => i,
    ).where((i) => players[i].isAlive).toList();
    final lb = lowerBound(livingIndices, playerIndex);

    final leftNeighborLivingIndex = lb == 0 ? livingIndices.length - 1 : lb - 1;
    final leftNeighbor = livingIndices[leftNeighborLivingIndex];

    final rightNeighborLivingIndexProposal =
        (leftNeighborLivingIndex + 1) % livingIndices.length;
    final rightNeighborLivingIndex =
        livingIndices[rightNeighborLivingIndexProposal] == playerIndex
        ? (rightNeighborLivingIndexProposal + 1) % livingIndices.length
        : rightNeighborLivingIndexProposal;
    final rightNeighbor = livingIndices[rightNeighborLivingIndex];

    return (leftNeighbor, rightNeighbor);
  }

  /// Checks if any team has met its win conditions.
  WinCondition? checkWinConditions() {
    for (final cond in winConditions) {
      if (cond.hasWon(state)) {
        return cond;
      }
    }
    return null;
  }

  /// Returns the list of winning players if there is a winning team.
  ISet<({int index, Player player})>? winningPlayers() {
    final WinCondition? winner = checkWinConditions();
    if (winner == null) return null;

    final Set<int> winners = winner.winningPlayers(state).unlock;

    final nonWinningPlayers = List.generate(
      playerCount,
      (i) => i,
    ).toISet().difference(winners);
    for (final playerIndex in nonWinningPlayers) {
      for (final playerWinHook in playerWinHooks) {
        final bool? result = playerWinHook(state, winner, playerIndex);
        if (result == true) {
          winners.add(playerIndex);
        }
      }
    }

    return winners
        .where(
          (player) => playerWinHooks.none(
            (playerWinHook) => playerWinHook(state, winner, player) == false,
          ),
        )
        .map(
          (playerIndex) => (index: playerIndex, player: players[playerIndex]),
        )
        .toISet();
  }

  /// Transitions to the next valid phase, if any.
  void transitionToNextPhase() {
    final next = nextPhase;
    final previous = _phase;
    if (next != null) {
      if (dayCounter == 0 &&
          phase.index < GamePhase.nightActions.index &&
          next.index >= GamePhase.nightActions.index) {
        state.apply(FillVillagerRolesCommand());
      }
      if (!_phase.isNight && _pendingDeaths.isNotEmpty) {
        state.apply(ProcessPendingDeathsCommand());
      } else {
        if (next == GamePhase.dawn && _pendingDeaths.isNotEmpty) {
          state.apply(ProcessPendingDeathsCommand());
        }
        _phase = next;
        if (next == GamePhase.dawn) {
          if (!(startGameWithDay && previous == GamePhase.checkRoles)) {
            _dayCounter += 1;
          }
          for (final hook in dawnHooks) {
            hook(state, dayCounter);
          }
        } else if (next == GamePhase.dayActions ||
            next == GamePhase.nightActions) {
          state.apply(
            DetermineFirstDynamicActionIndexCommand(
              night: next == GamePhase.nightActions,
            ),
          );
        }
      }
      return;
    }
    throw StateError('No valid next phase from $phase');
  }

  /// Gets the next valid phase, if any.
  GamePhase? get nextPhase {
    for (var i = 1; i < GamePhase.values.length; i++) {
      final next = GamePhase.values.elementAt(
        (phase.index + i) % GamePhase.values.length,
      );
      if (isValidNextPhase(next)) {
        return next;
      }
    }
    return null;
  }

  /// Checks if the given phase is a valid next phase.
  bool isValidNextPhase(GamePhase next) {
    if (phase == GamePhase.gameOver) {
      return false;
    }
    switch (next) {
      case GamePhase.checkRoles:
        if (dayCounter > 0 || players.any((player) => player.role != null)) {
          return false;
        }
        break;
      case GamePhase.nightActions:
        if ((phase == GamePhase.checkRoles &&
                startGameWithDay &&
                dayCounter == 0) ||
            nightActionManager.orderedActions.none(
              (phaseInfo) => phaseInfo.conditioned(state),
            )) {
          return false;
        }
        break;
      case GamePhase.dayActions:
        if (dayActionManager.orderedActions.none(
          (phaseInfo) => phaseInfo.conditioned(state),
        )) {
          return false;
        }
        break;
      case GamePhase.gameOver:
        if (checkWinConditions() == null) return false;
        break;
      default:
        break;
    }
    return true;
  }
}

/// Current phase of the game.
enum GamePhase {
  /// Phase starting the night.
  dusk,

  /// Phase for checking roles in the first night.
  checkRoles,

  /// Phase for performing night actions.
  nightActions,

  /// Phase starting the day.
  dawn,

  /// Phase for performing day actions.
  dayActions,

  /// Phase when the game has ended.
  gameOver;

  /// Whether the phase is a night phase.
  bool get isNight =>
      index >= GamePhase.dusk.index && index < GamePhase.dawn.index;
}

@MappableClass(discriminatorValue: 'transitionToNextPhase')
class TransitionToNextPhaseCommand
    with TransitionToNextPhaseCommandMappable
    implements GameCommand {
  ({GamePhase phase, int day, CheckRolesData checkRolesData})? _previousState;

  @override
  void apply(GameData gameData) {
    _previousState = (
      phase: gameData.phase,
      day: gameData.dayCounter,
      checkRolesData: gameData.checkRolesData,
    );
    gameData.transitionToNextPhase();
  }

  @override
  bool get canBeUndone => _previousState != null;

  @override
  void undo(GameData gameData) {
    if (_previousState != null) {
      final (:phase, :day, :checkRolesData) = _previousState!;
      gameData._phase = phase;
      gameData._dayCounter = day;
      gameData.checkRolesData = checkRolesData;
    }
  }
}

@MappableClass(discriminatorValue: 'gameOver')
class GameOverCommand with GameOverCommandMappable implements GameCommand {
  GamePhase? _previousPhase;

  @override
  void apply(GameData gameData) {
    _previousPhase = gameData.phase;
    gameData._phase = GamePhase.gameOver;

    final winnerIndices =
        gameData.winningPlayers()?.map((entry) => entry.index).toISet() ??
        const ISet.empty();

    AppDatabaseHolder().database.gamesDao.endGame(
      gameData.state.id,
      winner: gameData.checkWinConditions(),
      winnerIndices: winnerIndices,
    );
  }

  @override
  bool get canBeUndone => _previousPhase != null;

  @override
  void undo(GameData gameData) {
    gameData._phase = _previousPhase!;
    _previousPhase = null;
  }
}

@MappableClass(discriminatorValue: 'processPendingDeaths')
class ProcessPendingDeathsCommand
    with ProcessPendingDeathsCommandMappable
    implements GameCommand {
  IMap<int, IList<DeathInformation>>? _previousPendingDeaths;

  @override
  void apply(GameData gameData) {
    _previousPendingDeaths = gameData.pendingDeaths;
    final pendingDeaths = gameData.pendingDeaths;
    for (final entry in pendingDeaths.entries) {
      final playerIndex = entry.key;
      final deathInfos = entry.value;
      for (final deathInfo in deathInfos) {
        gameData._markPlayerActuallyDead(playerIndex, deathInfo);
      }
    }
    gameData._unannouncedDeaths.addAll(pendingDeaths.keys);
    for (final entry in pendingDeaths.entries) {
      gameData._pendingDeaths[entry.key]?.removeWhere(
        (deathInfo) => entry.value.contains(deathInfo),
      );
      if (gameData._pendingDeaths[entry.key]?.isEmpty == true) {
        gameData._pendingDeaths.remove(entry.key);
      }
    }
    if (gameData._pendingDeaths.isNotEmpty) {
      gameData.state.apply(ProcessPendingDeathsCommand());
    }
  }

  @override
  bool get canBeUndone => _previousPendingDeaths != null;

  @override
  void undo(GameData gameData) {
    for (final entry in _previousPendingDeaths!.entries) {
      final playerIndex = entry.key;
      final deathInfos = entry.value;
      for (final deathInfo in deathInfos) {
        gameData._pendingDeaths[playerIndex] ??= [];
        gameData._pendingDeaths[playerIndex]!.add(deathInfo);
      }
      gameData.players[playerIndex].deathInformation.removeWhere(
        (info) => entry.value.contains(info),
      );
    }
    gameData._unannouncedDeaths.removeAll(_previousPendingDeaths!.keys);
    _previousPendingDeaths = null;
  }
}

@MappableClass(discriminatorValue: 'markDeathsAnnounced')
class MarkDeathsAnnouncedCommand
    with MarkDeathsAnnouncedCommandMappable
    implements GameCommand {
  ISet<int>? _previouslyUnannouncedDeaths;

  @override
  void apply(GameData gameData) {
    _previouslyUnannouncedDeaths = gameData.unannouncedDeaths;
    gameData._unannouncedDeaths.clear();
    if (gameData.firstPlayerWithPendingDeathAction == null &&
        gameData.checkWinConditions() != null) {
      gameData.state.apply(GameOverCommand());
    }
  }

  @override
  bool get canBeUndone => _previouslyUnannouncedDeaths != null;

  @override
  void undo(GameData gameData) {
    gameData._unannouncedDeaths.addAll(_previouslyUnannouncedDeaths!);
    _previouslyUnannouncedDeaths = null;
  }
}
