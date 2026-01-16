import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

enum Winner {
  village,
  werewolves,
  lovers;

  String winningHeadline(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (this) {
      case Winner.village:
        return localizations.screen_gameOver_winnerVillageHeadline;
      case Winner.werewolves:
        return localizations.screen_gameOver_winnerWerewolvesHeadline;
      case Winner.lovers:
        return localizations.screen_gameOver_winnerLoversHeadline;
    }
  }
}
