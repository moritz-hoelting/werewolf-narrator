import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/death_information.dart';
import 'package:werewolf_narrator/game/role/role.dart';

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
      final thisPlayerSet = ISet({
        gameState.players.indexWhere((element) => element.ofPlayer(this)),
      });
      return gameState.deathActionHooks.none(
        (hook) => hook(gameState, (this, deathInformation!), thisPlayerSet),
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
  String toString() => 'Player(name: $name, role: $role, isAlive: $isAlive)';
}

class PlayerView {
  const PlayerView(this._player);

  final Player _player;

  /// The name of the player.
  String get name => _player.name;

  /// The role assigned to the player.
  Role? get role => _player.role;

  /// Information about the player's death, if dead.
  DeathInformation? get deathInformation => _player.deathInformation;

  /// Whether the player has used their death action.
  bool get usedDeathAction => _player.usedDeathAction;

  /// Whether the player's death has been announced.
  bool get deathAnnounced => _player.deathAnnounced;

  /// Tags associated with the player, used for various game mechanics.
  ISet<Object> get tags => _player.tags.lock;

  /// Whether the player is currently alive.
  bool get isAlive => _player.isAlive;

  /// Whether the player is waiting to perform a death action.
  bool waitForDeathAction(GameState gameState) =>
      _player.waitForDeathAction(gameState);

  bool ofPlayer(Player player) => player == _player;

  @override
  String toString() => _player.toString();
}
