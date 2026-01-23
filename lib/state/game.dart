import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game_phase.dart';
import 'package:werewolf_narrator/team/team.dart';

typedef DeathHook =
    bool Function(GameState gameState, int playerIndex, DeathReason reason);

typedef ReviveHook = bool Function(GameState gameState, int playerIndex);

class GameState extends ChangeNotifier {
  final List<Player> players;
  final Map<TeamType, Team> teams;
  final Map<RoleType, int> roleCounts;

  final List<DeathHook> deathHooks = [];
  final List<ReviveHook> reviveHooks = [];

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

  (int, Player)? getRolePlayer(RoleType role) =>
      players.indexed.singleWhereOrNull(
        (player) =>
            player.$2.role != null && player.$2.role!.objectType == role,
      );
  (int, Player)? getRoleTypePlayer<T extends Role>() =>
      getRolePlayer(RoleType<T>());

  List<(int, Player)> getRolePlayers(RoleType role) => players.indexed
      .where(
        (player) =>
            player.$2.role != null && player.$2.role!.objectType == role,
      )
      .toList();
  List<(int, Player)> getRoleTypePlayers<T extends Role>() =>
      getRolePlayers(RoleType<T>());

  bool hasAliveRole(RoleType role) =>
      hasRole(role) &&
      players
          .where(
            (p) => p.role != null && p.role!.objectType == role && p.isAlive,
          )
          .isNotEmpty;
  bool hasAliveRoleType<T extends Role>() => hasAliveRole(RoleType<T>());

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

  bool playerAliveOrKilledThisCycle(int playerIndex) {
    return players[playerIndex].isAlive ||
        currentCycleDeaths.containsKey(playerIndex);
  }

  void witchHealPlayer(int playerIndex) {
    final currentCycleDeaths = this.currentCycleDeaths;
    if (currentCycleDeaths.containsKey(playerIndex)) {
      if (currentCycleDeaths[playerIndex] == DeathReason.werewolf) {
        markPlayerRevived(playerIndex);
        notifyListeners();
      }
    }
  }

  bool get pendingDeathActions =>
      players.any((player) => player.waitForDeathAction(this));

  bool get pendingDeathAnnouncements =>
      players.any((player) => !player.isAlive && !player.deathAnnounced);

  TeamType? checkWinConditions() {
    final alivePlayers = players.where((player) => player.isAlive).toList();
    final aliveTeams = alivePlayers
        .map((player) => player.role!.team(this))
        .toSet();
    if (aliveTeams.length == 1) {
      return aliveTeams.first;
    }
    if (alivePlayers.length == 2 &&
        aliveTeams.containsAll({WerewolvesTeam.type, VillageTeam.type})) {
      return LoversTeam.type;
    }
    return null;
  }

  bool transitionToNextPhase() {
    final next = nextPhase;
    if (next != null) {
      if (dayCounter == 0 &&
          phase.index < GamePhase.thief.index &&
          next.index >= GamePhase.thief.index) {
        fillVillagerRoles();
      }
      if (dayCounter == 0 &&
          phase.index <= GamePhase.thief.index &&
          next.index > GamePhase.thief.index) {
        removeUnassignedRoles();
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
      case GamePhase.thief:
        if (dayCounter > 0 || !hasAliveRoleType<ThiefRole>()) return false;
        break;
      case GamePhase.cupid:
        if (dayCounter > 0 || !hasAliveRoleType<CupidRole>()) return false;
        break;
      case GamePhase.seer:
        if (!hasAliveRoleType<SeerRole>()) return false;
        break;
      case GamePhase.werewolves:
        if (!hasAliveRoleType<WerewolfRole>()) return false;
        break;
      case GamePhase.witch:
        if (!hasAliveRoleType<WitchRole>()) return false;
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
