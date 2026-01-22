import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/roles.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/model/winner.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game_phase.dart';

class GameState extends ChangeNotifier {
  final List<Player> players;
  final Map<RoleType, int> roles;

  int dayCounter = 0;
  GamePhase _phase = GamePhase.dusk;
  GamePhase get phase => _phase;
  (int, int)? lovers;
  int? sheriff;
  bool witchHasHealPotion = true;
  bool witchHasKillPotion = true;

  GameState({required List<String> players, required this.roles})
    : players = players.map((name) => Player(name: name)).toList() {
    assert(
      players.length ==
          roles.entries.fold(
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

  bool hasRole(RoleType role) => roles.containsKey(role) && roles[role]! > 0;
  bool hasRoleType<T extends Role>() => hasRole(RoleType<T>());

  (int, Player)? getRolePlayer(RoleType role) => players.indexed
      .where(
        (player) =>
            player.$2.role != null && player.$2.role!.objectType == role,
      )
      .firstOrNull;
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
          .where((p) => p.role.runtimeType == role.type && p.isAlive)
          .isNotEmpty;
  bool hasAliveRoleType<T extends Role>() => hasAliveRole(RoleType<T>());

  void setPlayersRole(RoleType role, List<int> playerIndices) {
    for (final index in playerIndices) {
      players[index].role = RoleManager.instantiateRole(role);
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
    final allRoles = roles;
    final assignedRoles = players.map((player) => player.role).fold(
      <RoleType, int>{},
      (acc, element) {
        if (element != null) {
          acc[element.objectType] = (acc[element.objectType] ?? 0) + 1;
        }
        return acc;
      },
    );

    return allRoles.entries
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
      roles[entry.key] = (roles[entry.key] ?? 0) - entry.value;
      if (roles[entry.key]! <= 0) {
        roles.remove(entry.key);
      }
    }
    notifyListeners();
  }

  void setLovers(int playerAidx, int playerBidx) {
    lovers = (playerAidx, playerBidx);
    notifyListeners();
  }

  void markPlayerDead(
    int playerIndex,
    DeathReason deathReason, {
    bool? atNight,
    int? day,
  }) {
    players[playerIndex].markDead(
      DeathInformation(
        reason: deathReason,
        day: day ?? dayCounter,
        atNight: atNight ?? isNight,
      ),
    );
    if (lovers != null &&
        (playerIndex == lovers!.$1 || playerIndex == lovers!.$2)) {
      final otherLover = (playerIndex == lovers!.$1) ? lovers!.$2 : lovers!.$1;
      if (players[otherLover].isAlive) {
        players[otherLover].markDead(
          DeathInformation(
            reason: DeathReason.lover,
            day: day ?? dayCounter,
            atNight: atNight ?? isNight,
          ),
        );
      }
    }
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

  void revivePlayer(int playerIndex) {
    players[playerIndex].revive();
    if (lovers != null &&
        (playerIndex == lovers!.$1 || playerIndex == lovers!.$2)) {
      final otherLover = (playerIndex == lovers!.$1) ? lovers!.$2 : lovers!.$1;
      final otherDeathInformation = players[otherLover].deathInformation;
      if (otherDeathInformation != null &&
          otherDeathInformation.reason == DeathReason.lover) {
        players[otherLover].revive();
      }
    }
    notifyListeners();
  }

  void witchHealPlayer(int playerIndex) {
    final currentCycleDeaths = this.currentCycleDeaths;
    if (currentCycleDeaths.containsKey(playerIndex)) {
      if (currentCycleDeaths[playerIndex] == DeathReason.werewolf) {
        revivePlayer(playerIndex);
        notifyListeners();
      }
    }
  }

  void witchUseUpPotion({bool heal = false, bool kill = false}) {
    if (heal) {
      witchHasHealPotion = false;
    }
    if (kill) {
      witchHasKillPotion = false;
    }
    if (heal || kill) {
      notifyListeners();
    }
  }

  bool get pendingDeathActions =>
      players.any((player) => player.waitForDeathAction(this));

  bool get pendingDeathAnnouncements =>
      players.any((player) => !player.isAlive && !player.deathAnnounced);

  Winner? checkWinConditions() {
    final alivePlayers = players.where((player) => player.isAlive).toList();
    final aliveTeams = alivePlayers
        .map((player) => player.role!.team(this))
        .toSet();
    if (aliveTeams.length == 1) {
      return aliveTeams.first.toWinner;
    }
    if (alivePlayers.length == 2 &&
        aliveTeams.containsAll({Team.werewolves, Team.village})) {
      return Winner.lovers;
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
      case GamePhase.checkRoleSeer:
        if (dayCounter > 0 || !hasRoleType<SeerRole>()) return false;
        break;
      case GamePhase.checkRoleWitch:
        if (dayCounter > 0 || !hasRoleType<WitchRole>()) return false;
        break;
      case GamePhase.checkRoleHunter:
        if (dayCounter > 0 || !hasRoleType<HunterRole>()) return false;
        break;
      case GamePhase.checkRoleCupid:
        if (dayCounter > 0 || !hasRoleType<CupidRole>()) return false;
        break;
      case GamePhase.checkRoleLittleGirl:
        if (dayCounter > 0 || !hasRoleType<LittleGirlRole>()) return false;
        break;
      case GamePhase.checkRoleWerewolves:
        if (dayCounter > 0 || !hasRoleType<WerewolfRole>()) return false;
        break;
      case GamePhase.checkRoleThief:
        if (dayCounter > 0 || !hasRoleType<ThiefRole>()) return false;
        break;
      case GamePhase.thief:
        if (dayCounter > 0 || !hasAliveRoleType<ThiefRole>()) return false;
        break;
      case GamePhase.cupid:
        if (dayCounter > 0 || !hasAliveRoleType<CupidRole>()) return false;
        break;
      case GamePhase.lovers:
        if (dayCounter > 0 || !hasRoleType<CupidRole>()) return false;
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
