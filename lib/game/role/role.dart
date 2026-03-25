import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/game_state.dart';

@sealed
abstract class Role {
  Role({required this.playerIndex});

  final int playerIndex;

  Option<TeamType?> overrideTeam = Option.none();

  @override
  String toString() {
    return runtimeType.toString();
  }

  /// The unique type of this role.
  RoleType get objectType;

  /// Called when this role is assigned to a player.
  void onAssign(GameState gameState) {}

  /// The team of this role in the current game state.
  TeamType? team(GameState gameState) =>
      overrideTeam.getOrElse(() => objectType.information.initialTeam);

  /// The display name of this role.
  String name(BuildContext context) => objectType.information.name(context);

  /// Whether this role has a death screen.
  bool hasDeathScreen(GameState gameState) => false;

  /// The widget builder for the death action screen.
  WidgetBuilder? deathActionScreen(VoidCallback onComplete, int playerIndex) =>
      null;
}
