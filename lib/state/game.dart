import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/role/villager.dart' show VillagerRole;
import 'package:werewolf_narrator/state/game_phase.dart';
import 'package:werewolf_narrator/team/team.dart';
import 'package:werewolf_narrator/state/night_actions.dart';

typedef DeathHook =
    bool Function(GameState gameState, int playerIndex, DeathReason reason);

typedef ReviveHook = bool Function(GameState gameState, int playerIndex);

typedef RemainingRoleHook =
    void Function(GameState gameState, int remainingCount);

typedef PlayerWinHook =
    bool? Function(GameState gameState, Team winningTeam, int playerIndex);

class GameState extends ChangeNotifier {
  /// Handles night actions for this game state.
  final NightActionManager nightActionManager = NightActionManager();

  /// The list of players in this game.
  final List<Player> players;

  /// The teams present in this game.
  final Map<TeamType, Team> teams;

  /// The counts of roles present in this game (initialized during setup).
  final Map<RoleType, int> roleCounts;

  /// Hooks when a player is marked dead.
  ///
  /// Can prevent death by returning true.
  final List<DeathHook> deathHooks = [];

  /// Hooks when a player is marked revived.
  ///
  /// Can prevent revival by returning true.
  final List<ReviveHook> reviveHooks = [];

  /// Hooks for remaining roles at the end of role assignment.
  ///
  /// Called with the count of remaining roles for each role type.
  final Map<RoleType, List<RemainingRoleHook>> remainingRoleHooks = {};

  /// Hooks to determine if a player has won alongside the winning team.
  ///
  /// Returning true adds the player as a winner, false excludes them,
  /// and null has no effect.
  final List<PlayerWinHook> playerWinHooks = [];

  int _dayCounter = 0;
  GamePhase _phase = GamePhase.dusk;

  /// The index of the current sheriff, if any.
  int? sheriff;

  // Guards against recursive calls in markPlayerDead and markPlayerRevived.
  final List<int> _markDeadRecursionGuard = [];
  final List<int> _markRevivedRecursionGuard = [];

  GameState({required List<String> players, required this.roleCounts})
    : players = players.map((name) => Player(name: name)).toList(),
      teams = Map.fromEntries(
        roleCounts.entries
            .where((entry) => entry.value > 0)
            .map((entry) => entry.key.instance.initialTeam)
            .toSet()
            .map(
              (teamType) =>
                  MapEntry(teamType, TeamManager.instantiateTeam(teamType)),
            ),
      ) {
    assert(
      players.length ==
          roleCounts.entries.fold(
            0,
            (sum, entry) =>
                sum +
                entry.value +
                (entry.value * (1 - entry.key.instance.addedRoleCardAmount)),
          ),
      'Number of players must match total number of roles assigned (correctly accounting for Thief roles)',
    );
    for (final team in teams.values) {
      team.initialize(this);
    }
    for (final role in roleCounts.keys) {
      final roleInitializer = RoleManager.getInitializer(role);
      if (roleInitializer != null) {
        roleInitializer(this);
      }
    }
  }

  /// Notifies listeners of updates to the game state.
  void notifyUpdate() {
    notifyListeners();
  }

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
  Map<int, DeathReason> deathsInCycle(int dayCounter, bool atNight) =>
      Map.unmodifiable(
        players.asMap().entries.fold({}, (acc, entry) {
          final playerIndex = entry.key;
          final deathInfo = entry.value.deathInformation;
          if (deathInfo != null &&
              deathInfo.atNight == atNight &&
              deathInfo.day == dayCounter) {
            acc[playerIndex] = deathInfo.reason;
          }
          return acc;
        }),
      );

  /// Returns a map of player indices to their death reasons for the current cycle (day/night).
  Map<int, DeathReason> get currentCycleDeaths =>
      deathsInCycle(dayCounter, isNight);

  /// Returns a map of player indices to their death reasons for the previous cycle (day/night).
  Map<int, DeathReason> get previousCycleDeaths =>
      deathsInCycle(isNight ? dayCounter : dayCounter - 1, !isNight);

  /// Returns a map of player indices to their unannounced death information.
  Map<int, DeathInformation> get unannouncedDeaths => Map.unmodifiable(
    players.asMap().entries.fold({}, (acc, entry) {
      final playerIndex = entry.key;
      final player = entry.value;
      final deathInfo = player.deathInformation;
      if (deathInfo != null && !player.deathAnnounced) {
        acc[playerIndex] = deathInfo;
      }
      return acc;
    }),
  );

  /// Checks if the game has a specific role.
  bool hasRole(RoleType role) =>
      roleCounts.containsKey(role) && roleCounts[role]! > 0;

  /// Checks if the game has a specific role.
  bool hasRoleType<T extends Role>() => hasRole(RoleType<T>());

  /// Checks if the game has a specific role with at least one alive player.
  bool hasAliveRole(RoleType role) =>
      hasRole(role) &&
      players.indexed.any(
        (p) =>
            p.$2.role != null &&
            p.$2.role!.objectType == role &&
            playerAliveUntilDawn(p.$1),
      );

  /// Checks if the game has a specific role with at least one alive player.
  bool hasAliveRoleType<T extends Role>() => hasAliveRole(RoleType<T>());

  /// Returns index and the player with a specific role, if any.
  (int, Player)? getPlayerOfRole(RoleType role) =>
      players.indexed.singleWhereOrNull(
        (player) =>
            player.$2.role != null && player.$2.role!.objectType == role,
      );

  /// Returns index and the player with a specific role, if any.
  (int, Player)? getPlayerOfRoleType<T extends Role>() =>
      getPlayerOfRole(RoleType<T>());

  /// Returns index and the alive player with a specific role, if any.
  (int, Player)? getAlivePlayerOfRole(RoleType role) =>
      players.indexed.singleWhereOrNull(
        (player) =>
            player.$2.role != null &&
            player.$2.role!.objectType == role &&
            playerAliveUntilDawn(player.$1),
      );

  /// Returns index and the alive player with a specific role, if any.
  (int, Player)? getAlivePlayerOfRoleType<T extends Role>() =>
      getAlivePlayerOfRole(RoleType<T>());

  /// Returns a list of indices and players with a specific role.
  List<(int, Player)> getPlayersOfRole(RoleType role) => players.indexed
      .where(
        (player) =>
            player.$2.role != null && player.$2.role!.objectType == role,
      )
      .toList();

  /// Returns a list of indices and players with a specific role.
  List<(int, Player)> getPlayersOfRoleType<T extends Role>() =>
      getPlayersOfRole(RoleType<T>());

  /// Returns a list of indices and alive players with a specific role.
  List<(int, Player)> getAlivePlayersOfRole(RoleType role) => players.indexed
      .where(
        (player) =>
            player.$2.role != null &&
            player.$2.role!.objectType == role &&
            playerAliveUntilDawn(player.$1),
      )
      .toList();

  /// Returns a list of indices and alive players with a specific role.
  List<(int, Player)> getAlivePlayersOfRoleType<T extends Role>() =>
      getAlivePlayersOfRole(RoleType<T>());

  /// Checks if the game has a specific team.
  bool hasPlayerOfTeam(TeamType team) => players.any(
    (player) => player.role != null && player.role!.team(this) == team,
  );

  /// Checks if the game has a specific team.
  bool hasPlayerOfTeamType<T extends Team>() => hasPlayerOfTeam(TeamType<T>());

  /// Checks if the game has an alive player of the specific team.
  bool hasAlivePlayerOfTeam(TeamType team) => players.indexed.any(
    (player) =>
        playerAliveUntilDawn(player.$1) &&
        player.$2.role != null &&
        player.$2.role!.team(this) == team,
  );

  /// Checks if the game has an alive player of the specific team.
  bool hasAlivePlayerOfTeamType<T extends Team>() =>
      hasAlivePlayerOfTeam(TeamType<T>());

  /// Returns a list of indices and players belonging to a specific team.
  List<(int, Player)> getPlayersOfTeam(TeamType team) => players.indexed
      .where(
        (player) =>
            player.$2.role != null && player.$2.role!.team(this) == team,
      )
      .toList();

  /// Returns a list of indices and players belonging to a specific team.
  List<(int, Player)> getPlayersOfTeamType<T extends Team>() =>
      getPlayersOfTeam(TeamType<T>());

  /// Returns a list of indices and alive players belonging to a specific team.
  List<(int, Player)> getAlivePlayersOfTeam(TeamType team) => players.indexed
      .where(
        (player) =>
            player.$2.role != null &&
            player.$2.role!.team(this) == team &&
            playerAliveUntilDawn(player.$1),
      )
      .toList();

  /// Returns a list of indices and alive players belonging to a specific team.
  List<(int, Player)> getAlivePlayersOfTeamType<T extends Team>() =>
      getAlivePlayersOfTeam(TeamType<T>());

  /// Assigns the specified role to the players at the given indices.
  void setPlayersRole(RoleType role, List<int> playerIndices) {
    for (final index in playerIndices) {
      final Role playerRole = RoleManager.instantiateRole(role);
      players[index].role = playerRole;
      playerRole.onAssign(this, index);
    }
    notifyListeners();
  }

  /// Fills all unassigned players with the Villager role.
  void fillVillagerRoles() {
    final unassignedPlayers = players
        .asMap()
        .entries
        .where((entry) => entry.value.role == null)
        .map((entry) => entry.key)
        .toList();
    setPlayersRole(VillagerRole.type, unassignedPlayers);
  }

  /// Returns a list of unassigned roles in the game.
  List<RoleType> get unassignedRoles {
    final assignedRoles = players.map((player) => player.role).fold(
      <RoleType, int>{},
      (acc, element) {
        if (element != null) {
          acc[element.objectType] = (acc[element.objectType] ?? 0) + 1;
        }
        return acc;
      },
    );

    return roleCounts.entries
        .map((entry) {
          final assignedCount = assignedRoles[entry.key] ?? 0;
          return (entry.key, entry.value - assignedCount);
        })
        .fold(<RoleType>[], (acc, element) {
          for (int i = 0; i < element.$2; i++) {
            acc.add(element.$1);
          }
          return acc;
        });
  }

  /// Removes unassigned roles from the role counts.
  void removeUnassignedRoles() {
    final unassignedRoles = this.unassignedRoles.fold(<RoleType, int>{}, (
      acc,
      element,
    ) {
      acc[element] = (acc[element] ?? 0) + 1;
      return acc;
    });
    for (final entry in unassignedRoles.entries) {
      roleCounts[entry.key] = (roleCounts[entry.key] ?? 0) - entry.value;
      if (roleCounts[entry.key]! <= 0) {
        roleCounts.remove(entry.key);
      }
    }
    notifyListeners();
  }

  /// Marks a player as dead with the given death reason.
  void markPlayerDead(int playerIndex, DeathReason deathReason) {
    if (_markDeadRecursionGuard.contains(playerIndex)) {
      return;
    }
    _markDeadRecursionGuard.add(playerIndex);
    bool shouldDie = true;
    for (final hook in deathHooks) {
      if (hook(this, playerIndex, deathReason)) {
        shouldDie = false;
      }
    }
    if (shouldDie) {
      players[playerIndex].markDead(
        DeathInformation(
          reason: deathReason,
          day: dayCounter,
          atNight: isNight,
        ),
      );
    }
    _markDeadRecursionGuard.remove(playerIndex);
    notifyListeners();
  }

  /// Marks a player as revived.
  void markPlayerRevived(int playerIndex) {
    if (_markRevivedRecursionGuard.contains(playerIndex)) {
      return;
    }
    _markRevivedRecursionGuard.add(playerIndex);
    bool shouldRevive = true;
    for (final hook in reviveHooks) {
      if (hook(this, playerIndex)) {
        shouldRevive = false;
      }
    }
    if (shouldRevive) {
      players[playerIndex].markRevived();
    }
    _markRevivedRecursionGuard.remove(playerIndex);
    notifyListeners();
  }

  /// Marks that a player has used their death action.
  void markPlayerUsedDeathAction(int playerIndex) {
    players[playerIndex].usedDeathAction = true;
    notifyListeners();
  }

  /// Marks all deaths as announced and checks for game over conditions.
  void markDeathsAnnounced() {
    for (var playerIndex in unannouncedDeaths.keys) {
      players[playerIndex].deathAnnounced = true;
    }
    if (checkWinConditions() != null) {
      _phase = GamePhase.gameOver;
    }
    notifyListeners();
  }

  /// Checks if a player is alive or killed in the current cycle.
  bool playerAliveOrKilledThisCycle(int playerIndex) =>
      players[playerIndex].isAlive ||
      currentCycleDeaths.containsKey(playerIndex);

  /// Checks if a player is alive or will remain alive until dawn.
  bool playerAliveUntilDawn(int playerIndex) =>
      players[playerIndex].isAlive ||
      (isNight && currentCycleDeaths.containsKey(playerIndex));

  /// Whether there are pending death actions to be resolved.
  bool get pendingDeathActions =>
      players.any((player) => player.waitForDeathAction(this));

  /// Whether there are pending death announcements to be made.
  bool get pendingDeathAnnouncements =>
      players.any((player) => !player.isAlive && !player.deathAnnounced);

  /// Checks if any team has met its win conditions.
  Team? checkWinConditions() {
    for (final team in teams.values) {
      if (team.hasWon(this)) {
        return team;
      }
    }
    return null;
  }

  /// Returns the list of winning players if there is a winning team.
  List<(int, Player)>? winningPlayers() {
    final Team? winningTeam = checkWinConditions();
    if (winningTeam == null) return null;

    final List<(int, Player)> winners = winningTeam.winningPlayers(this);

    final nonWinningPlayers = List.generate(
      playerCount,
      (i) => i,
    ).toSet().difference(winners.map((player) => player.$1).toSet());
    for (final playerIndex in nonWinningPlayers) {
      for (final playerWinHook in playerWinHooks) {
        final bool? result = playerWinHook(this, winningTeam, playerIndex);
        if (result == true) {
          winners.add((playerIndex, players[playerIndex]));
        }
      }
    }

    return winners
        .where(
          (player) => playerWinHooks.none(
            (playerWinHook) =>
                playerWinHook(this, winningTeam, player.$1) == false,
          ),
        )
        .toList();
  }

  /// Transitions to the next valid phase, if any.
  bool transitionToNextPhase() {
    final next = nextPhase;
    if (next != null) {
      if (dayCounter == 0 &&
          phase.index < GamePhase.nightActions.index &&
          next.index >= GamePhase.nightActions.index) {
        fillVillagerRoles();
      }
      _phase = next;
      if (next == GamePhase.dawn) {
        _dayCounter += 1;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Gets the next valid phase, if any.
  GamePhase? get nextPhase {
    for (int i = 1; i < GamePhase.values.length; i++) {
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
        final bool hasAnyRoleOtherThanVillager = roleCounts.entries.any(
          (entry) => entry.value > 0 && entry.key != VillagerRole.type,
        );
        if (dayCounter > 0 || !hasAnyRoleOtherThanVillager) return false;
        break;
      case GamePhase.nightActions:
        if (nightActionManager.nightActions.none(
          (phaseInfo) => phaseInfo.conditioned(this),
        )) {
          return false;
        }
        break;
      case GamePhase.sheriffElection:
        if (sheriff != null && players[sheriff!].isAlive) return false;
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
