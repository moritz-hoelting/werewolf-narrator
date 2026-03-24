import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/game_command.dart' show GameCommand;
import 'package:werewolf_narrator/game/game_data.dart' show GameData;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/misc/phases/voting.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/util/hooks.dart' show PlayerDisplayData;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class SheriffVoteAction {
  SheriffVoteAction._();

  int? sheriffIndex;

  static void registerAction(GameState gameState) {
    gameState.apply(
      RegisterSheriffElectionScreenCommand(SheriffVoteAction._()),
    );
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
      appBarTitle: Text(localizations.screen_villageVote_sheriffLabel),
      instruction: Text(
        localizations.screen_sheriffElection_instruction,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actionIdentifier: SheriffVoteAction,
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

class RegisterSheriffElectionScreenCommand implements GameCommand {
  const RegisterSheriffElectionScreenCommand(this.sheriffVoteAction);

  final SheriffVoteAction sheriffVoteAction;

  @override
  void apply(GameData gameData) {
    gameData.dayActionManager.registerAction(
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
      before: IList([VillageVoteScreen]),
      players: const {},
    );

    gameData.playerDisplayHooks.add(playerDisplayHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.dayActionManager.unregisterAction(SheriffVoteAction);
    gameData.playerDisplayHooks.remove(playerDisplayHook);
  }

  PlayerDisplayData? playerDisplayHook(
    GameState gameState,
    Object? phaseIdentifier,
    int playerIndex,
  ) {
    if (phaseIdentifier == VillageVoteScreen &&
        sheriffVoteAction.sheriffIndex == playerIndex) {
      return PlayerDisplayData(
        trailing: (context) => const Icon(Icons.local_police_outlined),
      );
    } else {
      return null;
    }
  }
}
