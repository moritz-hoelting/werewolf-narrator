import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/team.dart';

part 'lovers.dart';
part 'village.dart';
part 'werewolves.dart';

sealed class Team {
  const Team();

  String name(BuildContext context);

  String winningHeadline(BuildContext context);
}
