import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/roles.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'cupid.dart';
part 'hunter.dart';
part 'little_girl.dart';
part 'seer.dart';
part 'thief.dart';
part 'villager.dart';
part 'werewolf.dart';
part 'witch.dart';

sealed class Role {
  const Role();

  @override
  String toString() {
    return runtimeType.toString();
  }

  RoleType get objectType;

  bool get isUnique;
  Team get initialTeam;
  Team team(GameState gameState) => initialTeam;

  String name(BuildContext context);
  String description(BuildContext context);
  String checkRoleInstruction(BuildContext context, int count);

  bool hasDeathScreen(GameState gameState) => false;
  WidgetBuilder? deathActionScreen(VoidCallback onComplete) => null;

  bool hasNightScreen(GameState gameState) => false;
  WidgetBuilder? nightActionScreen(VoidCallback onComplete) => null;
}
