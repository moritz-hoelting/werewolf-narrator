import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart' show GameData;
import 'package:werewolf_narrator/game/game_state.dart';

part 'death_actions_screen.mapper.dart';

class DeathActionsScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const DeathActionsScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    GameState gameState = Provider.of<GameState>(context, listen: false);

    final int? playerIndex = gameState.firstPlayerWithPendingDeathAction;

    if (playerIndex == null) {
      Future.microtask(onPhaseComplete);
    }

    final deathAction = gameState.players[playerIndex!].role!.deathActionScreen(
      () {
        gameState.apply(MarkPlayerUsedDeathActionCommand(playerIndex));

        if (gameState.firstPlayerWithPendingDeathAction == null) {
          onPhaseComplete();
        } else {
          gameState.finishBatch();
        }
      },
      playerIndex,
    )!;

    return deathAction(context);
  }
}

@MappableClass(discriminatorValue: 'markPlayerUsedDeathAction')
class MarkPlayerUsedDeathActionCommand
    with MarkPlayerUsedDeathActionCommandMappable
    implements GameCommand {
  final int playerIndex;

  MarkPlayerUsedDeathActionCommand(this.playerIndex);

  bool? _previousUsedDeathAction;

  @override
  void apply(GameData gameData) {
    final player = gameData.players[playerIndex];
    _previousUsedDeathAction = player.usedDeathAction;
    player.usedDeathAction = true;
  }

  @override
  bool get canBeUndone => _previousUsedDeathAction != null;

  @override
  void undo(GameData gameData) {
    final player = gameData.players[playerIndex];
    player.usedDeathAction = _previousUsedDeathAction!;
    _previousUsedDeathAction = null;
  }
}
