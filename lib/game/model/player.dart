import 'package:collection/collection.dart';
import 'package:werewolf_narrator/game/model/death_information.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';

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

  /// Tags associated with the player, used for various game mechanics.
  final Set<Object> tags = {};

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
    if (role!.hasDeathScreen(gameState)) {
      return gameState.deathActionHooks.none(
        (hook) => hook(
          gameState,
          (this, deathInformation!),
          {gameState.players.indexOf(this)},
        ),
      );
    }
    return false;
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
