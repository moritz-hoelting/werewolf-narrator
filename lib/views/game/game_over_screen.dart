import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/player.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final winnerOrNull = gameState.checkWinConditions();

        assert(
          winnerOrNull != null,
          'GameOverScreen should only be shown when there is a winner',
        );

        final WinCondition winner = winnerOrNull!;
        final List<PlayerView> winners = gameState
            .winningPlayers()!
            .map((entry) => entry.player)
            .toList();

        return Scaffold(
          appBar: GameAppBar(
            title: Text(localizations.screen_gameOver_title),
            exitGameButton: false,
            automaticallyImplyLeading: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  winner.winningHeadline(context),
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
