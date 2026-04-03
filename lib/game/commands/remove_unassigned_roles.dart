import 'package:dart_mappable/dart_mappable.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/role.dart' show RoleType;
import 'package:werewolf_narrator/game/model/role_config.dart'
    show RoleConfiguration;

part 'remove_unassigned_roles.mapper.dart';

/// Removes unassigned roles from the role counts.
@MappableClass(discriminatorValue: 'removeUnassignedRoles')
class RemoveUnassignedRolesCommand
    with RemoveUnassignedRolesCommandMappable
    implements GameCommand {
  Map<RoleType, ({RoleConfiguration config, int count})>? _removedRoles;

  @override
  void apply(GameData gameData) {
    final unassignedRoles = gameData.unassignedRoles.fold(
      <RoleType, ({int count, RoleConfiguration config})>{},
      (acc, element) {
        final count = (acc[element]?.count ?? 0) + 1;
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
