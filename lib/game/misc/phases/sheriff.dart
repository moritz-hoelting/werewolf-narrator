import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart' show GameData;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/misc/phases/voting.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart'
    show BoolOption;
import 'package:werewolf_narrator/game/util/dynamic_actions.dart'
    show DynamicActionIdentifier;
import 'package:werewolf_narrator/game/util/hooks.dart' show PlayerDisplayData;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'sheriff.mapper.dart';

final sheriffEnabledOption = BoolOption(
  id: 'enableSheriff',
  label: (context) =>
      AppLocalizations.of(context).configurationOption_enableSheriff_label,
  description: (context) => AppLocalizations.of(
    context,
  ).configurationOption_enableSheriff_description,
  defaultValue: true,
);

class SheriffElectionScreen extends StatelessWidget {
  const SheriffElectionScreen({required this.onComplete, super.key});

  static const identifier = _SheriffElectionScreenIdentifier();

  final VoidCallback onComplete;

  static void registerAction(GameState gameState) {
    gameState.apply(const RegisterSheriffElectionScreenCommand());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ActionScreen(
      appBarTitle: Text(localizations.screen_villageVote_sheriffLabel),
      instruction: Text(
        localizations.screen_sheriffElection_instruction,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actionIdentifier: SheriffElectionScreen,
      selectionCount: 1,
      allowSelectLess: true,
      onConfirm: (selectedPlayers, gameState) {
        if (selectedPlayers.isNotEmpty) {
          gameState.apply(ElectSheriffCommand(selectedPlayers.single));
        }
        onComplete();
      },
    );
  }
}

class _SheriffElectionScreenIdentifier implements DynamicActionIdentifier {
  const _SheriffElectionScreenIdentifier();
}

@MappableClass(discriminatorValue: 'registerSheriffElectionScreen')
class RegisterSheriffElectionScreenCommand
    with RegisterSheriffElectionScreenCommandMappable
    implements GameCommand {
  const RegisterSheriffElectionScreenCommand();

  @override
  void apply(GameData gameData) {
    gameData.dayActionManager.registerAction(
      SheriffElectionScreen.identifier,
      (gameState, onComplete) =>
          (context) => SheriffElectionScreen(onComplete: onComplete),
      conditioned: (gameState) =>
          gameState.alivePlayerCount > 1 &&
          (gameData.customData[SheriffElectionScreen] == null ||
              !gameState
                  .players[gameData.customData[SheriffElectionScreen] as int]
                  .isAlive),
      before: ISet({VillageVoteScreen.identifier}),
      players: const {},
    );

    gameData.playerDisplayHooks.add(playerDisplayHook);

    gameData.customData[SheriffElectionScreen] = null;
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.dayActionManager.unregisterAction(
      SheriffElectionScreen.identifier,
    );
    gameData.playerDisplayHooks.remove(playerDisplayHook);
  }

  PlayerDisplayData? playerDisplayHook(
    GameState gameState,
    Object? phaseIdentifier,
    int playerIndex,
  ) {
    if (phaseIdentifier == VillageVoteScreen &&
        gameState.customData[SheriffElectionScreen] == playerIndex) {
      return PlayerDisplayData(
        trailing: (context) => const Icon(Icons.local_police_outlined),
      );
    } else {
      return null;
    }
  }
}

@MappableClass(discriminatorValue: 'electSheriff')
class ElectSheriffCommand
    with ElectSheriffCommandMappable
    implements GameCommand {
  const ElectSheriffCommand(this.sheriffIndex);

  final int sheriffIndex;

  @override
  void apply(GameData gameData) {
    gameData.customData[SheriffElectionScreen] = sheriffIndex;
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.customData[SheriffElectionScreen] = null;
  }
}
