import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/game/game_command.dart' show GameCommand;
import 'package:werewolf_narrator/game/game_data.dart' show GameData;
import 'package:werewolf_narrator/game/model/role.dart'
    show RoleType, RoleManager;
import 'package:werewolf_narrator/game/role/role.dart' show Role;

class SetPlayersRoleCommand implements GameCommand {
  final RoleType role;
  final ISet<int> players;

  SetPlayersRoleCommand(this.role, this.players);

  Map<int, Role?>? _previousRoles;

  @override
  void apply(GameData gameData) {
    _previousRoles = {};
    for (final index in players) {
      _previousRoles![index] = gameData.players[index].role;
      final Role playerRole = RoleManager.instantiateRole(
        index,
        role,
        gameData.roleConfigurations[role]?.config ?? {},
      );
      gameData.players[index].role = playerRole;
      playerRole.onAssign(gameData.state);
    }
  }

  @override
  bool get canBeUndone => _previousRoles != null;

  @override
  void undo(GameData gameData) {
    for (final entry in _previousRoles!.entries) {
      final index = entry.key;
      final previousRole = entry.value;
      if (previousRole != null) {
        gameData.players[index].role = previousRole;
        previousRole.onAssign(gameData.state);
      } else {
        gameData.players[index].role = null;
      }
    }
    _previousRoles = null;
  }
}
