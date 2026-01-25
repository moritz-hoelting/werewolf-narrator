import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';

@sealed
abstract class Team {
  const Team();

  TeamType get objectType;
  void initialize(GameState gameState) {}

  String name(BuildContext context);

  String winningHeadline(BuildContext context);

  bool hasWon(GameState gameState);
  List<(int, Player)> winningPlayers(GameState gameState) => gameState
      .players
      .indexed
      .where((player) => player.$2.role?.team(gameState) == objectType)
      .toList();
}
