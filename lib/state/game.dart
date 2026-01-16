import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/model/winner.dart';
import 'package:werewolf_narrator/state/game_phase.dart';

class GameState extends ChangeNotifier {
  final List<Player> players;
  final Map<Role, int> roles;

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
      players.length == roles.values.fold(0, (sum, count) => sum + count),
      'Number of players must match total number of roles assigned',
    );
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

  bool hasRole(Role role) => roles.containsKey(role) && roles[role]! > 0;

  bool hasAliveRole(Role role) =>
      hasRole(role) &&
      players.where((p) => p.role == role && p.isAlive).isNotEmpty;

  void setPlayersRole(Role role, List<int> playerIndices) {
    for (final index in playerIndices) {
      players[index].role = role;
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
    setPlayersRole(Role.villager, unassignedPlayers);
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
      players.any((player) => player.waitForDeathAction);

  bool get pendingDeathAnnouncements =>
      players.any((player) => !player.isAlive && !player.deathAnnounced);

  Winner? checkWinConditions() {
    final alivePlayers = players.where((player) => player.isAlive).toList();
    final aliveTeams = alivePlayers.map((player) => player.role!.team).toSet();
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
          phase.index < GamePhase.cupid.index &&
          next.index >= GamePhase.cupid.index) {
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
      case GamePhase.checkRoleSeer:
        if (dayCounter > 0 || !hasRole(Role.seer)) return false;
        break;
      case GamePhase.checkRoleWitch:
        if (dayCounter > 0 || !hasRole(Role.witch)) return false;
        break;
      case GamePhase.checkRoleHunter:
        if (dayCounter > 0 || !hasRole(Role.hunter)) return false;
        break;
      case GamePhase.checkRoleCupid:
        if (dayCounter > 0 || !hasRole(Role.cupid)) return false;
        break;
      case GamePhase.checkRoleLittleGirl:
        if (dayCounter > 0 || !hasRole(Role.littleGirl)) return false;
        break;
      case GamePhase.checkRoleWerewolves:
        if (dayCounter > 0 || !hasRole(Role.werewolf)) return false;
        break;
      case GamePhase.cupid:
        if (dayCounter > 0 || !hasAliveRole(Role.cupid)) return false;
        break;
      case GamePhase.lovers:
        if (dayCounter > 0 || !hasRole(Role.cupid)) return false;
        break;
      case GamePhase.seer:
        if (!hasAliveRole(Role.seer)) return false;
        break;
      case GamePhase.werewolves:
        if (!hasAliveRole(Role.werewolf)) return false;
        break;
      case GamePhase.witch:
        if (!hasAliveRole(Role.witch)) return false;
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
