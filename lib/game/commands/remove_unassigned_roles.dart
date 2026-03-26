import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/role.dart' show RoleType;
import 'package:werewolf_narrator/game/model/role_config.dart'
    show RoleConfiguration;
import 'package:werewolf_narrator/game/role/role.dart' show Role;

/// Removes unassigned roles from the role counts.
class RemoveUnassignedRolesCommand implements GameCommand {
  Map<RoleType<Role>, ({RoleConfiguration config, int count})>? _removedRoles;

  @override
  void apply(GameData gameData) {
    final unassignedRoles = gameData.unassignedRoles.fold(
      <RoleType, ({int count, RoleConfiguration config})>{},
      (acc, element) {
        int count = (acc[element]?.count ?? 0) + 1;
        acc[element] = (
          count: count,
          config:
              acc[element]?.config ??
              gameData.roleConfigurations[element]?.config ??
              {},
        );
        return acc;
      },
    );
    _removedRoles = unassignedRoles;
    for (final entry in unassignedRoles.entries) {
      gameData.roleConfigurations[entry.key] = (
        count:
            (gameData.roleConfigurations[entry.key]?.count ?? 0) -
            entry.value.count,
        config: gameData.roleConfigurations[entry.key]?.config ?? {},
      );
      if (gameData.roleConfigurations[entry.key]!.count <= 0) {
        gameData.roleConfigurations.remove(entry.key);
      }
    }
  }

  @override
  bool get canBeUndone => _removedRoles != null;

  @override
  void undo(GameData gameData) {
    for (final entry in _removedRoles!.entries) {
      gameData.roleConfigurations[entry.key] = (
        count:
            (gameData.roleConfigurations[entry.key]?.count ?? 0) +
            entry.value.count,
        config:
            gameData.roleConfigurations[entry.key]?.config ??
            entry.value.config,
      );
    }
  }
}
