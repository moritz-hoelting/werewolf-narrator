import 'package:dart_mappable/dart_mappable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/team.dart';

part 'override_team.mapper.dart';

@MappableClass(discriminatorValue: 'overrideTeam')
class OverrideTeamCommand
    with OverrideTeamCommandMappable
    implements GameCommand {
  OverrideTeamCommand(this.playerIndex, this.team);

  final int playerIndex;
  final TeamType team;

  Option<TeamType?>? _previousOverride;

  @override
  void apply(GameData gameData) {
    _previousOverride = gameData.players[playerIndex].role?.overrideTeam;
    gameData.players[playerIndex].role?.overrideTeam = Option.of(team);
  }

  @override
  bool get canBeUndone => _previousOverride != null;

  @override
  void undo(GameData gameData) {
    gameData.players[playerIndex].role?.overrideTeam = _previousOverride!;
  }
}
