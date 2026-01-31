import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game.dart';

/// A player in the game.
class Player {
  /// The name of the player.
  final String name;

  /// The role assigned to the player.
  Role? role;

  /// Information about the player's death, if dead.
  DeathInformation? _deathInformation;

  /// Whether the player has used their death action.
  bool usedDeathAction = false;

  /// Whether the player's death has been announced.
  bool deathAnnounced = false;

  Player({required this.name, this.role, DeathInformation? deathInformation})
    : _deathInformation = deathInformation;

  /// Information about the player's death, if dead.
  DeathInformation? get deathInformation => _deathInformation;

  /// Whether the player is currently alive.
  bool get isAlive => _deathInformation == null;

  /// Whether the player is waiting to perform a death action.
  bool waitForDeathAction(GameState gameState) {
    if (isAlive || usedDeathAction || role == null) {
      return false;
    }
    return role!.hasDeathScreen(gameState);
  }

  /// Marks the player as dead with the given death information.
  void markDead(DeathInformation deathInfo) {
    _deathInformation = deathInfo;
  }

  /// Marks the player as revived.
  void markRevived() {
    _deathInformation = null;
  }

  @override
  String toString() {
    return 'Player(name: $name, role: $role, isAlive: $isAlive)';
  }
}
