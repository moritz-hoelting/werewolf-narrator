import 'package:flutter/material.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';

abstract interface class WinCondition {
  /// The headline displayed when having won.
  String winningHeadline(BuildContext context);

  /// Whether having won the game at the current state.
  bool hasWon(GameState gameState);

  /// The players that have won the game.
  List<(int, Player)> winningPlayers(GameState gameState);
}

/// Determines the winning players by team.
List<(int, Player)> teamWinningPlayers(
  GameState gameState,
  TeamType teamType,
) => gameState.players.indexed
    .where((player) => player.$2.role?.team(gameState) == teamType)
    .toList();
