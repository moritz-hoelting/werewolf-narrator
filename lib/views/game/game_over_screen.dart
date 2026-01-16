import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/model/winner.dart';
import 'package:werewolf_narrator/state/game.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final winningTeam = gameState.checkWinConditions();

        if (winningTeam == null) {
          // Should not happen, but keep it safe
          return Scaffold(
            appBar: AppBar(title: Text(localizations.screen_gameOver_title)),
            body: Center(
              child: Text(
                localizations.screen_gameOver_noWinner,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final bool loversDifferentTeams =
            gameState.lovers != null &&
            gameState.players[gameState.lovers!.$1].role?.team !=
                gameState.players[gameState.lovers!.$2].role?.team;

        final lovers = [gameState.lovers?.$1, gameState.lovers?.$2].nonNulls;

        List<Player> winners;
        switch (winningTeam) {
          case Winner.village:
            winners = gameState.players
                .asMap()
                .entries
                .where(
                  (entry) =>
                      entry.value.role?.team == Team.village &&
                      (!loversDifferentTeams || !lovers.contains(entry.key)),
                )
                .map((entry) => entry.value)
                .toList();
            break;

          case Winner.werewolves:
            winners = gameState.players
                .asMap()
                .entries
                .where(
                  (entry) =>
                      entry.value.role?.team == Team.werewolves &&
                      (!loversDifferentTeams || !lovers.contains(entry.key)),
                )
                .map((entry) => entry.value)
                .toList();
            break;

          case Winner.lovers:
            winners = gameState.players
                .asMap()
                .entries
                .where((entry) => lovers.contains(entry.key))
                .map((entry) => entry.value)
                .toList();
            break;
        }

        return Scaffold(
          appBar: AppBar(title: Text(localizations.screen_gameOver_title)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  winningTeam.winningHeadline(context),
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  localizations.screen_gameOver_winnersLabel,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                ...winners.map(
                  (player) => Text(
                    player.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
