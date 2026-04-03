import 'package:meta/meta.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/team.dart';

@sealed
abstract class Team {
  const Team();

  /// The unique type of this team.
  TeamType get teamType;

  /// Called when the team is first initialized in the game.
  void initialize(GameState gameState) {}
}
