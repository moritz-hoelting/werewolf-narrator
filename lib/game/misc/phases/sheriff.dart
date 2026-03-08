import 'package:flutter/material.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/misc/phases/voting.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/util/hooks.dart' show PlayerDisplayData;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class SheriffVoteAction {
  SheriffVoteAction._();

  int? sheriffIndex;

  static void registerAction(GameState gameState) {
    final sheriffVoteAction = SheriffVoteAction._();

    gameState.dayActionManager.registerAction(
      SheriffVoteAction,
      (gameState, onComplete) =>
          (context) => SheriffElectionScreen(
            sheriffVoteAction: sheriffVoteAction,
            onComplete: onComplete,
          ),
      conditioned: (gameState) =>
          gameState.alivePlayerCount > 1 &&
          (sheriffVoteAction.sheriffIndex == null ||
              !gameState.players[sheriffVoteAction.sheriffIndex!].isAlive),
      before: [VillageVoteScreen],
      players: {},
    );

    gameState.playerDisplayHooks.add((gameState, phaseIdentifier, playerIndex) {
      if (phaseIdentifier == VillageVoteScreen &&
          sheriffVoteAction.sheriffIndex == playerIndex) {
        return PlayerDisplayData(
          trailing: (context) => const Icon(Icons.local_police_outlined),
        );
      } else {
        return null;
      }
    });
  }
}

class SheriffElectionScreen extends StatelessWidget {
  const SheriffElectionScreen({
    super.key,
    required this.sheriffVoteAction,
    required this.onComplete,
  });

  final VoidCallback onComplete;
  final SheriffVoteAction sheriffVoteAction;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ActionScreen(
      appBarTitle: Text(localizations.screen_sheriffElection_instruction),
      selectionCount: 1,
      allowSelectLess: true,
      onConfirm: (selectedPlayers, gameState) {
        if (selectedPlayers.isNotEmpty) {
          sheriffVoteAction.sheriffIndex = selectedPlayers.single;
        }
        onComplete();
      },
    );
  }
}
