import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/team.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final winningTeamOrNull = gameState.checkWinConditions();

        assert(
          winningTeamOrNull != null,
          'GameOverScreen should only be shown when there is a winner',
        );

        final Team winningTeam = winningTeamOrNull!;
        List<Player> winners = gameState
            .winningPlayers()!
            .map((entry) => entry.$2)
            .toList();

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
