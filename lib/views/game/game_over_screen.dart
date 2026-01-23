import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/player.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/team.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final winningTeamOrNull = gameState.checkWinConditions();

        assert(
          winningTeamOrNull != null,
          'GameOverScreen should only be shown when there is a winner',
        );

        final winningTeam = winningTeamOrNull!;

        // final bool loversDifferentTeams =
        //     gameState.lovers != null &&
        //     gameState.players[gameState.lovers!.$1].role?.team(gameState) !=
        //         gameState.players[gameState.lovers!.$2].role?.team(gameState);

        // final lovers = [gameState.lovers?.$1, gameState.lovers?.$2].nonNulls;

        // TODO: Dummy values to avoid errors
        final bool loversDifferentTeams = true;
        final lovers = <int>[0, 1];

        List<Player> winners;
        switch (winningTeam) {
          case TeamType<VillageTeam>():
            winners = gameState.players
                .whereIndexed(
                  (index, player) =>
                      player.role?.team(gameState) == VillageTeam.type &&
                      (!loversDifferentTeams || !lovers.contains(index)),
                )
                .toList();
            break;

          case TeamType<WerewolvesTeam>():
            winners = gameState.players
                .whereIndexed(
                  (index, player) =>
                      player.role?.team(gameState) == WerewolvesTeam.type &&
                      (!loversDifferentTeams || !lovers.contains(index)),
                )
                .toList();
            break;

          case TeamType<LoversTeam>():
            winners = gameState.players
                .whereIndexed((index, player) => lovers.contains(index))
                .toList();
            break;

          default:
            winners = [];
            break;
        }

        return Scaffold(
          appBar: AppBar(title: Text(localizations.screen_gameOver_title)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  winningTeam.instance.winningHeadline(context),
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
