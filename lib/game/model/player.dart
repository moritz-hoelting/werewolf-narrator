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

  /// Information about the player's death, if dead.  The first entry corresponds to the death that will be shown.
  final List<DeathInformation> _deathInformation = [];

  /// Whether the player has used their death action.
  bool usedDeathAction = false;

  /// Tags associated with the player, used for various game mechanics.
  final Set<Object> tags = {};

  Player(this.name);

  /// Information about the player's death, if dead. The first entry corresponds to the death that will be shown.
  List<DeathInformation> get deathInformation => _deathInformation;

  /// Whether the player is currently alive.
  bool get isAlive => _deathInformation.isEmpty;

  /// Whether the player is waiting to perform a death action.
  bool waitForDeathAction(GameState gameState) {
    if (isAlive || usedDeathAction || role == null) {
      return false;
    }
    if (role!.hasDeathScreen(gameState)) {
      final playerIndex = gameState.players.indexWhere(
        (element) => element.ofPlayer(this),
      );
      return gameState.deathActionHooks.none(
        (hook) => hook(gameState, (this, deathInformation), playerIndex),
      );
    }
    return false;
  }

  /// Marks the player as dead with the given death information.
  void markDead(DeathInformation deathInfo) {
    _deathInformation.add(deathInfo);
  }

  /// Marks the player as revived.
  void markRevived() {
    _deathInformation.clear();
    usedDeathAction = false;
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
  IList<DeathInformation> get deathInformation => _player.deathInformation.lock;

  /// Whether the player has used their death action.
  bool get usedDeathAction => _player.usedDeathAction;

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
