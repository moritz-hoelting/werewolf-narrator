import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
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
  final NightActionManager nightActionManager = NightActionManager();

  final List<Player> players;
  final Map<TeamType, Team> teams;
  final Map<RoleType, int> roleCounts;

  final List<DeathHook> deathHooks = [];
  final List<ReviveHook> reviveHooks = [];
  final Map<RoleType, List<RemainingRoleHook>> remainingRoleHooks = {};
  final List<PlayerWinHook> playerWinHooks = [];

  int dayCounter = 0;
  GamePhase _phase = GamePhase.dusk;
  GamePhase get phase => _phase;
  int? sheriff;

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
                (entry.key == ThiefRole.type ? entry.value * -2 : 0),
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

  void notifyUpdate() {
    notifyListeners();
  }

  bool get isNight => phase.isNight;
  int get playerCount => players.length;
  int get alivePlayerCount => players.where((player) => player.isAlive).length;

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

  Map<int, DeathReason> get currentCycleDeaths =>
      deathsInCycle(dayCounter, isNight);

  Map<int, DeathReason> get previousCycleDeaths =>
      deathsInCycle(isNight ? dayCounter : dayCounter - 1, !isNight);

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

  bool hasRole(RoleType role) =>
      roleCounts.containsKey(role) && roleCounts[role]! > 0;
  bool hasRoleType<T extends Role>() => hasRole(RoleType<T>());

  bool hasAliveRole(RoleType role) =>
      hasRole(role) &&
      players.indexed.any(
        (p) =>
            p.$2.role != null &&
            p.$2.role!.objectType == role &&
            playerAliveUntilDawn(p.$1),
      );
  bool hasAliveRoleType<T extends Role>() => hasAliveRole(RoleType<T>());

  (int, Player)? getPlayerOfRole(RoleType role) =>
      players.indexed.singleWhereOrNull(
        (player) =>
            player.$2.role != null && player.$2.role!.objectType == role,
      );
  (int, Player)? getPlayerOfRoleType<T extends Role>() =>
      getPlayerOfRole(RoleType<T>());
  (int, Player)? getAlivePlayerOfRole(RoleType role) =>
      players.indexed.singleWhereOrNull(
        (player) =>
            player.$2.role != null &&
            player.$2.role!.objectType == role &&
            playerAliveUntilDawn(player.$1),
      );
  (int, Player)? getAlivePlayerOfRoleType<T extends Role>() =>
      getAlivePlayerOfRole(RoleType<T>());

  List<(int, Player)> getPlayersOfRole(RoleType role) => players.indexed
      .where(
        (player) =>
            player.$2.role != null && player.$2.role!.objectType == role,
      )
      .toList();
  List<(int, Player)> getPlayersOfRoleType<T extends Role>() =>
      getPlayersOfRole(RoleType<T>());
  List<(int, Player)> getAlivePlayersOfRole(RoleType role) => players.indexed
      .where(
        (player) =>
            player.$2.role != null &&
            player.$2.role!.objectType == role &&
            playerAliveUntilDawn(player.$1),
      )
      .toList();
  List<(int, Player)> getAlivePlayersOfRoleType<T extends Role>() =>
      getAlivePlayersOfRole(RoleType<T>());

  bool hasPlayerOfTeam(TeamType team) => players.any(
    (player) => player.role != null && player.role!.team(this) == team,
  );
  bool hasPlayerOfTeamType<T extends Team>() => hasPlayerOfTeam(TeamType<T>());
  bool hasAlivePlayerOfTeam(TeamType team) => players.indexed.any(
    (player) =>
        playerAliveUntilDawn(player.$1) &&
        player.$2.role != null &&
        player.$2.role!.team(this) == team,
  );
  bool hasAlivePlayerOfTeamType<T extends Team>() =>
      hasAlivePlayerOfTeam(TeamType<T>());

  List<(int, Player)> getPlayersOfTeam(TeamType team) => players.indexed
      .where(
        (player) =>
            player.$2.role != null && player.$2.role!.team(this) == team,
      )
      .toList();
  List<(int, Player)> getPlayersOfTeamType<T extends Team>() =>
      getPlayersOfTeam(TeamType<T>());
  List<(int, Player)> getAlivePlayersOfTeam(TeamType team) => players.indexed
      .where(
        (player) =>
            player.$2.role != null &&
            player.$2.role!.team(this) == team &&
            playerAliveUntilDawn(player.$1),
      )
      .toList();
  List<(int, Player)> getAlivePlayersOfTeamType<T extends Team>() =>
      getAlivePlayersOfTeam(TeamType<T>());

  void setPlayersRole(RoleType role, List<int> playerIndices) {
    for (final index in playerIndices) {
      final Role playerRole = RoleManager.instantiateRole(role);
      players[index].role = playerRole;
      playerRole.onAssign(this, index);
    }
    notifyListeners();
  }

  void fillVillagerRoles() {
    final unassignedPlayers = players
        .asMap()
        .entries
        .where((entry) => entry.value.role == null)
        .map((entry) => entry.key)
        .toList();
    setPlayersRole(VillagerRole.type, unassignedPlayers);
  }

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

  void markPlayerDead(
    int playerIndex,
    DeathReason deathReason, {
    bool? atNight,
    int? day,
  }) {
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
          day: day ?? dayCounter,
          atNight: atNight ?? isNight,
        ),
      );
    }
    _markDeadRecursionGuard.remove(playerIndex);
    notifyListeners();
  }

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

  void markPlayerUsedDeathAction(int playerIndex) {
    players[playerIndex].usedDeathAction = true;
    notifyListeners();
  }

  void markDeathsAnnounced() {
    for (var playerIndex in unannouncedDeaths.keys) {
      players[playerIndex].deathAnnounced = true;
    }
    if (checkWinConditions() != null) {
      _phase = GamePhase.gameOver;
    }
    notifyListeners();
  }

  bool playerAliveOrKilledThisCycle(int playerIndex) =>
      players[playerIndex].isAlive ||
      currentCycleDeaths.containsKey(playerIndex);

  bool playerAliveUntilDawn(int playerIndex) =>
      players[playerIndex].isAlive ||
      (isNight && currentCycleDeaths.containsKey(playerIndex));

  bool get pendingDeathActions =>
      players.any((player) => player.waitForDeathAction(this));

  bool get pendingDeathAnnouncements =>
      players.any((player) => !player.isAlive && !player.deathAnnounced);

  Team? checkWinConditions() {
    for (final team in teams.values) {
      if (team.hasWon(this)) {
        return team;
      }
    }
    return null;
  }

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
        dayCounter += 1;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

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
