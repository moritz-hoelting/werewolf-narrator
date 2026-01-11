import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/role.dart';

class GameState extends ChangeNotifier {
  final List<Player> players;
  final Map<Role, int> roles;

  int dayCounter = 0;
  GamePhase phase = GamePhase.dusk;

  GameState({required List<String> players, required this.roles})
    : players = players.map((name) => Player(name: name)).toList() {
    assert(
      players.length == roles.values.fold(0, (sum, count) => sum + count),
      'Number of players must match total number of roles assigned',
    );
  }

  bool get isNight => phase.isNight;
  int get playerCount => players.length;

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

  void markPlayerDead(int playerIndex) {
    players[playerIndex].isAlive = false;
    notifyListeners();
  }

  bool transitionToNextPhase() {
    final next = nextPhase;
    if (next != null) {
      phase = next;
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
      case GamePhase.checkRoleWerewolves:
        if (dayCounter > 0 || !hasRole(Role.werewolf)) return false;
        break;
      case GamePhase.cupid:
        if (dayCounter > 0 || !hasAliveRole(Role.cupid)) return false;
        break;
      case GamePhase.lovers:
        if (dayCounter > 0) return false;
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
      default:
        break;
    }
    return true;
  }
}

class Player {
  final String name;
  Role? role;
  bool isAlive;

  Player({required this.name, this.role, this.isAlive = true});

  @override
  String toString() {
    return 'Player(name: $name, role: $role, isAlive: $isAlive)';
  }
}

enum GamePhase {
  dusk,
  checkRoleSeer,
  checkRoleWitch,
  checkRoleHunter,
  checkRoleCupid,
  checkRoleWerewolves,
  cupid,
  lovers,
  seer,
  werewolves,
  witch,
  dawn,
  voting;

  bool get isNight => this != dawn && this != voting;
}
