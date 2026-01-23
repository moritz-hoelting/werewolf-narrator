part of 'team.dart';

class VillageTeam extends Team {
  const VillageTeam._();
  static final TeamType type = TeamType<VillageTeam>();
  static const Team instance = VillageTeam._();

  static void registerTeam() {
    TeamManager.registerRole<VillageTeam>(
      RegisterTeamInformation(VillageTeam._, instance),
    );
  }

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context)!.team_village_name;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context)!.team_village_winHeadline;
}
