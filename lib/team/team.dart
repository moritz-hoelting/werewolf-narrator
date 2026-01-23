import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'lovers.dart';
part 'village.dart';
part 'werewolves.dart';

sealed class Team {
  const Team();

  String name(BuildContext context);

  String winningHeadline(BuildContext context);

  bool hasNightScreen(GameState gameState) => false;
  WidgetBuilder? nightActionScreen(VoidCallback onComplete) => null;
}
