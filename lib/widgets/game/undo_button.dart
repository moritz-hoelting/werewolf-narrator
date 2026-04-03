import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

class UndoButton extends StatelessWidget {
  const UndoButton({super.key});

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, gameState, child) => IconButton(
      onPressed: gameState.canUndoBatch
          ? () {
              gameState.undoBatch();
            }
          : null,
      icon: child!,
      tooltip: AppLocalizations.of(context).button_undoTooltip,
    ),
    child: const Icon(Icons.undo),
  );
}
