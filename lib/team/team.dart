import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';

@sealed
abstract class Team {
  const Team();

  /// The unique type of this team.
  TeamType get objectType;

  /// Called when the team is first initialized in the game.
  void initialize(GameState gameState) {}

  /// If non-null, the roles of this team are checked together in the check role screen.
  /// Then, the returned RoleType is used to determine unassigned roles at the end.
  ///
  /// If null, the roles of this team are checked separately.
  RoleType? get roleCheckTogether => null;

  /// The display name of this team.
  String name(BuildContext context);

  /// The instruction for checking this team.
  String checkTeamInstruction(BuildContext context, int count) {
    throw UnimplementedError('This team has no check team instruction');
  }

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
