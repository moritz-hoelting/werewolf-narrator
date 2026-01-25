part of 'team.dart';

class LoversTeam extends Team {
  const LoversTeam._() : lovers = null;
  const LoversTeam.withLovers(this.lovers);
  static final TeamType type = TeamType<LoversTeam>();
  @override
  TeamType get objectType => type;
  static const Team instance = LoversTeam._();

  final (int, int)? lovers;

  static void registerTeam() {
    TeamManager.registerTeam<LoversTeam>(
      RegisterTeamInformation(LoversTeam._, instance),
    );
  }

  @override
  void initialize(GameState gameState) {
    super.initialize(gameState);

    gameState.deathHooks.add((gameState, playerIndex, reason) {
      if (reason != DeathReason.lover &&
          lovers != null &&
          (playerIndex == lovers!.$1 || playerIndex == lovers!.$2)) {
        final int otherLoverIndex = playerIndex == lovers!.$1
            ? lovers!.$2
            : lovers!.$1;
        gameState.markPlayerDead(otherLoverIndex, DeathReason.lover);
      }

      return false;
    });

    gameState.reviveHooks.add((gameState, playerIndex) {
      if (lovers != null &&
          (playerIndex == lovers!.$1 || playerIndex == lovers!.$2)) {
        final int otherLoverIndex = playerIndex == lovers!.$1
            ? lovers!.$2
            : lovers!.$1;
        gameState.markPlayerRevived(otherLoverIndex);
      }

      return false;
    });

    if (lovers != null) {
      gameState.playerWinHooks.add((gameState, winningTeam, playerIndex) {
        if (winningTeam.objectType != LoversTeam.type &&
            (playerIndex == lovers!.$1 || playerIndex == lovers!.$2)) {
          if (gameState.players[lovers!.$1].role?.team(gameState) !=
              gameState.players[lovers!.$2].role?.team(gameState)) {
            return false;
          }
        }

        return null;
      });
    }
  }

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context)!.team_lovers_name;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context)!.team_lovers_winHeadline;

  @override
  bool hasWon(GameState gameState) =>
      lovers != null &&
      setEquals(
        gameState.players.indexed
            .where((player) => player.$2.isAlive)
            .map((player) => player.$1)
            .toSet(),
        {lovers!.$1, lovers!.$2},
      );
  @override
  List<(int, Player)> winningPlayers(GameState gameState) {
    if (lovers == null) {
      return [];
    }

    return gameState.players.indexed
        .where((player) => player.$1 == lovers!.$1 || player.$1 == lovers!.$2)
        .toList();
  }
}
