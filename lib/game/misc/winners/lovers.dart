import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition;
import 'package:werewolf_narrator/game/game_state.dart';

class Lovers implements DeathReason, WinCondition {
  const Lovers(this.lovers);

  final ISet<int> lovers;

  void initialize(GameState gameState) {
    gameState.deathHooks.add((gameState, playerIndex, reason) {
      if (reason is! Lovers && lovers.contains(playerIndex)) {
        final ISet<int> otherLovers = lovers.difference({playerIndex});
        for (int loverIndex in otherLovers) {
          gameState.markPlayerDead(loverIndex, this);
        }
      }

      return false;
    });

    gameState.reviveHooks.add((gameState, playerIndex) {
      if (lovers.contains(playerIndex)) {
        final ISet<int> otherLovers = lovers.difference({playerIndex});
        for (int loverIndex in otherLovers) {
          gameState.markPlayerRevived(loverIndex);
        }
      }

      return false;
    });

    gameState.playerWinHooks.add((gameState, winners, playerIndex) {
      if (winners is! Lovers && lovers.contains(playerIndex)) {
        if (lovers
                .map(
                  (playerIndex) =>
                      gameState.players[playerIndex].role?.team(gameState),
                )
                .toISet()
                .length >
            1) {
          return false;
        }
      }

      return null;
    });
  }

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).lovers_winHeadline;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).lovers_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => lovers;

  @override
  bool hasWon(GameState gameState) => lovers.equalItems(
    gameState.players.indexed
        .where((player) => player.$2.isAlive)
        .map((player) => player.$1)
        .toSet(),
  );

  @override
  ISet<int> winningPlayers(GameState gameState) => lovers;
}
