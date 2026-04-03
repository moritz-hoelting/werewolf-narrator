import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/team.dart';

part 'win_condition.mapper.dart';

@MappableClass(discriminatorKey: 'type')
abstract interface class WinCondition with WinConditionMappable {
  /// The headline displayed when having won.
  String winningHeadline(BuildContext context);

  /// Whether having won the game at the current state.
  bool hasWon(GameState gameState);

  /// The players that have won the game.
  ISet<int> winningPlayers(GameState gameState);
}

/// Determines the winning players by team.
ISet<int> teamWinningPlayers(GameState gameState, TeamType teamType) =>
    gameState.players.indexed
        .where((player) => player.$2.role?.team(gameState) == teamType)
        .map((player) => player.$1)
        .toISet();
