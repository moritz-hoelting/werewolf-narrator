part of 'team.dart';

class VillageTeam extends Team {
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
  bool hasWon(GameState gameState) => setEquals(
    gameState.players
        .where((player) => player.isAlive)
        .map((player) => player.role?.team(gameState))
        .toSet(),
    {VillageTeam.type},
  );
}
