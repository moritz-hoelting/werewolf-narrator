import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/role.dart' show RoleType;

/// Removes unassigned roles from the role counts.
class RemoveUnassignedRolesCommand implements GameCommand {
  @override
  void apply(GameData gameData) {
    final unassignedRoles = gameData.unassignedRoles.fold(<RoleType, int>{}, (
      acc,
      element,
    ) {
      acc[element] = (acc[element] ?? 0) + 1;
      return acc;
    });
    for (final entry in unassignedRoles.entries) {
      gameData.roleConfigurations[entry.key] = (
        count:
            (gameData.roleConfigurations[entry.key]?.count ?? 0) - entry.value,
        config: gameData.roleConfigurations[entry.key]?.config ?? {},
      );
      if (gameData.roleConfigurations[entry.key]!.count <= 0) {
        gameData.roleConfigurations.remove(entry.key);
      }
    }
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }
}
