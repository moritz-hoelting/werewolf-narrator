part of 'team.dart';

class WerewolvesTeam extends Team {
  const WerewolvesTeam._();
  static final TeamType type = TeamType<WerewolvesTeam>();
  static const Team instance = WerewolvesTeam._();

  static void registerTeam() {
    TeamManager.registerRole<WerewolvesTeam>(
      RegisterTeamInformation(WerewolvesTeam._, instance),
    );
  }

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context)!.team_werewolves_name;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context)!.team_werewolves_winHeadline;
}
