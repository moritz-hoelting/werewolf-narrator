import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';

@sealed
abstract class Team {
  const Team();

  /// The unique type of this team.
  TeamType get objectType;

  /// Called when the team is first initialized in the game.
  void initialize(GameState gameState) {}

  /// The display name of this team.
  String name(BuildContext context);

  /// The headline displayed when this team wins.
  String winningHeadline(BuildContext context);

  /// Whether this team has won the game at the current state.
  bool hasWon(GameState gameState);

  /// The players that belong to this team and have won the game.
  List<(int, Player)> winningPlayers(GameState gameState) => gameState
      .players
      .indexed
      .where((player) => player.$2.role?.team(gameState) == objectType)
      .toList();
}
