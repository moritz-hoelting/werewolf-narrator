import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/team.dart';

class OverrideTeamCommand implements GameCommand {
  OverrideTeamCommand(this.playerIndex, this.team);

  final int playerIndex;
  final TeamType team;

  Option<TeamType?>? previousOverride;

  @override
  void apply(GameData gameData) {
    previousOverride = gameData.players[playerIndex].role?.overrideTeam;
    gameData.players[playerIndex].role?.overrideTeam = Option.of(team);
  }

  @override
  bool get canBeUndone => previousOverride != null;

  @override
  void undo(GameData gameData) {
    gameData.players[playerIndex].role?.overrideTeam = previousOverride!;
  }
}
