import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:werewolf_narrator/game/game_command.dart' show GameCommand;
import 'package:werewolf_narrator/game/game_data.dart' show GameData;
import 'package:werewolf_narrator/game/model/role.dart' show RoleType;

class SetPlayersRoleCommand implements GameCommand {
  final RoleType role;
  final ISet<int> players;

  SetPlayersRoleCommand(this.role, this.players);

  @override
  void apply(GameData gameData) {
    gameData.setPlayersRole(role, players);
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: fix
    throw UnimplementedError();
  }
}
