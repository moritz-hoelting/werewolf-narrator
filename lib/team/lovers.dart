part of 'team.dart';

class LoversTeam extends Team {
  const LoversTeam._();
  static final TeamType type = TeamType<LoversTeam>();
  static const Team instance = LoversTeam._();

  static void registerTeam() {
    TeamManager.registerRole<LoversTeam>(
      RegisterTeamInformation(LoversTeam._, instance),
    );
  }

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context)!.team_lovers_name;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context)!.team_lovers_winHeadline;
}
