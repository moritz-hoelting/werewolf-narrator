import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

class RedoButton extends StatelessWidget {
  const RedoButton({super.key});

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, gameState, child) => IconButton(
      onPressed: gameState.canRedoBatch
          ? () {
              gameState.redoBatch();
            }
          : null,
      icon: child!,
      tooltip: AppLocalizations.of(context).button_redoTooltip,
    ),
    child: const Icon(Icons.redo),
  );
}
