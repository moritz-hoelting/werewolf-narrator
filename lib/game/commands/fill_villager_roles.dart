import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/game/commands/set_players_role.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/role/village/villager.dart'
    show VillagerRole;

part 'fill_villager_roles.mapper.dart';

/// Fills all unassigned players with the Villager role.
@MappableClass(discriminatorValue: 'fillVillagerRoles')
class FillVillagerRolesCommand
    with FillVillagerRolesCommandMappable
    implements GameCommand {
  @override
  void apply(GameData gameData) {
    final unassignedPlayers = gameData.players
        .asMap()
        .entries
        .where((entry) => entry.value.role == null)
        .map((entry) => entry.key)
        .toISet();
    gameData.state.apply(
      SetPlayersRoleCommand(VillagerRole.type, unassignedPlayers),
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    // only applies commands, undo is automatically handled
  }
}
