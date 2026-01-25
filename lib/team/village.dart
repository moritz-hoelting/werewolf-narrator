import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/team.dart';

class VillageTeam extends Team implements DeathReason {
  const VillageTeam._();
  static final TeamType type = TeamType<VillageTeam>();
  @override
  TeamType get objectType => type;
  static const Team instance = VillageTeam._();

  static void registerTeam() {
    TeamManager.registerTeam<VillageTeam>(
      RegisterTeamInformation(VillageTeam._, instance),
    );
  }

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context)!.team_village_name;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context)!.team_village_winHeadline;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context)!.deathReason_villageVote;

  @override
  bool hasWon(GameState gameState) => setEquals(
    gameState.players
        .where((player) => player.isAlive)
        .map((player) => player.role?.team(gameState))
        .toSet(),
    {VillageTeam.type},
  );
}
