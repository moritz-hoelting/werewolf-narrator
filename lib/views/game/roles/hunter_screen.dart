import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

class HunterScreen extends StatelessWidget {
  final int playerIndex;
  final VoidCallback onPhaseComplete;

  const HunterScreen({
    super.key,
    required this.playerIndex,
    required this.onPhaseComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context)!;

        return ActionScreen(
          appBarTitle: Text(localizations.role_hunter_name),
          instruction: Text(
            localizations.screen_roleAction_instruction_hunter,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          disabledPlayerIndices: [playerIndex],
          selectionCount: 1,
          onConfirm: (selectedPlayers, gameState) {
            assert(
              selectedPlayers.length == 1,
              'Hunter must select exactly one player to shoot.',
            );
            gameState.markPlayerDead(selectedPlayers[0], DeathReason.hunter);
            onPhaseComplete();
          },
        );
      },
    );
  }
}
