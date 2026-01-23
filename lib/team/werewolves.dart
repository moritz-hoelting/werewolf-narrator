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

  @override
  bool hasNightScreen(GameState gameState) => true;
  @override
  WidgetBuilder? nightActionScreen(VoidCallback onComplete) => (context) {
    final localizations = AppLocalizations.of(context)!;
    final werewolvesOrDead = Provider.of<GameState>(context, listen: false)
        .players
        .indexed
        .where((player) => player.$2.role is WerewolfRole || !player.$2.isAlive)
        .map((player) => player.$1)
        .toList();
    return ActionScreen(
      appBarTitle: Text(localizations.role_werewolf_name),
      instruction: Text(localizations.screen_roleAction_instruction_werewolf),
      selectionCount: 1,
      disabledPlayerIndices: werewolvesOrDead,
      onConfirm: (selectedPlayers, gameState) {
        gameState.markPlayerDead(selectedPlayers[0], DeathReason.werewolf);
        onComplete();
      },
    );
  };
}
