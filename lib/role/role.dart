import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';

@sealed
abstract class Role {
  const Role();

  @override
  String toString() {
    return runtimeType.toString();
  }

  /// The unique type of this role.
  RoleType get objectType;

  /// Called when this role is assigned to a player.
  void onAssign(GameState gameState, int playerIndex) {}

  /// Whether this role is unique in the game.
  bool get isUnique;

  /// How many role cards are added to the game when this role is included.
  int get addedRoleCardAmount => 1;

  /// The initial team of this role.
  TeamType get initialTeam;

  /// The team of this role in the current game state.
  TeamType team(GameState gameState) => initialTeam;

  /// The display name of this role.
  String name(BuildContext context);

  /// The description of this role.
  String description(BuildContext context);

  /// The instruction for checking this role.
  String checkRoleInstruction(BuildContext context, int count);

  /// Whether this role has a death screen.
  bool hasDeathScreen(GameState gameState) => false;

  /// The widget builder for the death action screen.
  WidgetBuilder? deathActionScreen(VoidCallback onComplete, int playerIndex) =>
      null;
}
