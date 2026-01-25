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

  RoleType get objectType;

  void onAssign(GameState gameState, int playerIndex) {}

  bool get isUnique;
  int get addedRoleCardAmount => 1;
  TeamType get initialTeam;
  TeamType team(GameState gameState) => initialTeam;

  String name(BuildContext context);
  String description(BuildContext context);
  String checkRoleInstruction(BuildContext context, int count);

  bool hasDeathScreen(GameState gameState) => false;
  WidgetBuilder? deathActionScreen(VoidCallback onComplete, int playerIndex) =>
      null;
}
