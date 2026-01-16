import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

class SheriffElectionScreen extends StatelessWidget {
  const SheriffElectionScreen({super.key, required this.onPhaseComplete});

  final VoidCallback onPhaseComplete;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ActionScreen(
      appBarTitle: Text(localizations.screen_sheriffElection_instruction),
      disabledPlayerIndices: [],
      selectionCount: 1,
      allowSelectLess: true,
      onConfirm: (selectedPlayers, gameState) {
        if (selectedPlayers.length == 1) {
          gameState.sheriff = selectedPlayers[0];
        }
        onPhaseComplete();
      },
    );
  }
}
