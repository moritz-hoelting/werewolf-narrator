import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/player.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition;
import 'package:werewolf_narrator/game/game_state.dart';

class Lovers implements DeathReason, WinCondition {
  const Lovers(this.lovers);

  final (int, int) lovers;

  void initialize(GameState gameState) {
    gameState.deathHooks.add((gameState, playerIndex, reason) {
      if (reason is! Lovers &&
          (playerIndex == lovers.$1 || playerIndex == lovers.$2)) {
        final int otherLoverIndex = playerIndex == lovers.$1
            ? lovers.$2
            : lovers.$1;
        gameState.markPlayerDead(otherLoverIndex, this);
      }

      return false;
    });

    gameState.reviveHooks.add((gameState, playerIndex) {
      if ((playerIndex == lovers.$1 || playerIndex == lovers.$2)) {
        final int otherLoverIndex = playerIndex == lovers.$1
            ? lovers.$2
            : lovers.$1;
        gameState.markPlayerRevived(otherLoverIndex);
      }

      return false;
    });

    gameState.playerWinHooks.add((gameState, winners, playerIndex) {
      if (winners is! Lovers &&
          (playerIndex == lovers.$1 || playerIndex == lovers.$2)) {
        if (gameState.players[lovers.$1].role?.team(gameState) !=
            gameState.players[lovers.$2].role?.team(gameState)) {
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
  bool hasWon(GameState gameState) => setEquals(
    gameState.players.indexed
        .where((player) => player.$2.isAlive)
        .map((player) => player.$1)
        .toSet(),
    {lovers.$1, lovers.$2},
  );

  @override
  List<(int, Player)> winningPlayers(GameState gameState) {
    return gameState.players.indexed
        .where((player) => player.$1 == lovers.$1 || player.$1 == lovers.$2)
        .toList();
  }
}
